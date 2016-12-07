
#include "ParameterListModel.h"
#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "AnisotropyDecayGroup.h"
#include <QMetaProperty>

ParameterListItem::ParameterListItem(shared_ptr<QDecayModel> model)
{
   m_type = Root;
   m_parent = nullptr;

   int n_groups = model->getNumGroups();

   for (int i = 0; i < n_groups; i++)
      m_children.append(new ParameterListItem(model->getGroup(i), i, this));
}

ParameterListItem::ParameterListItem(shared_ptr<AbstractDecayGroup> group, int index, ParameterListItem* parent)
{
   m_type = Group;
   m_parent = parent;
   m_name = group->objectName();
   m_decay_group = group;

   const QMetaObject* group_meta = group->metaObject();
   int n_properties = group_meta->propertyCount();

   for (int i = 0; i < n_properties; i++)
   {
      const auto& prop = group_meta->property(i);
      if (prop.isUser())
         m_children.append(new ParameterListItem(group, prop, this));
   }

   m_children.append(new ParameterListItem(group, this));
}

void ParameterListItem::refresh()
{
   // if a group, refresh the parameters
   if (m_type == Group)
      m_children.last()->refresh();

   if (m_type == SubParameters)
   {
      qDeleteAll(m_children);
      m_children.clear();
      auto params = m_decay_group->getParameters();
      for (auto& p : params)
         m_children.append(new ParameterListItem(p, this));
   }
}

ParameterListItem::ParameterListItem(shared_ptr<AbstractDecayGroup> group, const QMetaProperty prop, ParameterListItem* parent)
{
   m_type = Option;
   m_parent = parent;
   m_name = prop.name();
   m_property = prop;
   m_decay_group = group;
}

ParameterListItem::ParameterListItem(shared_ptr<AbstractDecayGroup> group, ParameterListItem* parent)
{
   m_type = SubParameters;
   m_parent = parent;
   m_name = "Parameters";
   m_decay_group = group;

   refresh();
}

ParameterListItem::ParameterListItem(shared_ptr<FittingParameter> parameter, ParameterListItem* parent)
{
   m_parent = parent;
   m_type = Parameter;
   m_name = QString::fromStdString(parameter->name);
   m_parameter = parameter;
}

ParameterListItem::~ParameterListItem()
{
   qDeleteAll(m_children);
}

int ParameterListItem::row() const
{
   if (m_parent)
      return m_parent->m_children.indexOf(const_cast<ParameterListItem*>(this));

   return 0;
}

ParameterListModel::ParameterListModel(shared_ptr<QDecayModel> decay_model, QObject* parent) :
   QAbstractItemModel(parent),
   decay_model(decay_model)
{
   //connect(decay_model.get(), &DecayModel::Updated, this, &ParameterListModel::revert, Qt::QueuedConnection);
   root_item = new ParameterListItem(decay_model);
}


void ParameterListModel::parseDecayModel()
{
   beginResetModel();
   delete root_item;
   root_item = new ParameterListItem(decay_model);
   endResetModel();
}

ParameterListModel::~ParameterListModel()
{
   delete root_item;
}

QModelIndex ParameterListModel::index(int row, int column, const QModelIndex & parent) const
{
   if (!hasIndex(row, column, parent))
      return QModelIndex();

   ParameterListItem *parent_item = GetItem(parent);

   ParameterListItem *childItem = parent_item->child(row);
   if (childItem)
      return createIndex(row, column, childItem);
   else
      return QModelIndex();
}

QModelIndex ParameterListModel::parent(const QModelIndex & index) const
{
   if (!index.isValid())
      return QModelIndex();

   ParameterListItem *child_item = static_cast<ParameterListItem*>(index.internalPointer());
   ParameterListItem *parent_item = child_item->parent();

   if (parent_item == root_item)
      return QModelIndex();

   return createIndex(parent_item->row(), 0, parent_item);
}

QVariant ParameterListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
   if (role != Qt::DisplayRole)
      return QVariant();

   if (orientation == Qt::Orientation::Horizontal)
   {
      switch (section)
      {
      case 0:
         return "Parameter";
      case 1:
         return "Initial Value";
      case 2:
         return "Fitting type";
      }
   }
   return "";
}

QVariant ParameterListModel::data(const QModelIndex & index, int role) const
{
   if (role != Qt::DisplayRole && role != Qt::EditRole)
      return QVariant();

   auto item = GetItem(index);

   if (!index.isValid())
      return QVariant();

   if (index.column() == 0)
   {
      if (item->type() == ParameterListItem::Group)
         return item->decayGroup()->objectName();
      else
         return item->name();
   }

   if (item->type() == ParameterListItem::Parameter)
   {
      auto parameter = item->parameter();
      switch (index.column())
      {
      case 1:
         return parameter->initial_value;
      case 2:
         if (role == Qt::DisplayRole)
            return FittingParameter::fitting_type_names[parameter->fitting_type];
         else // EditRole
            return parameter->fitting_type;
      }
   }
   else if (item->type() == ParameterListItem::Option && index.column() == 1)
   {
      auto prop = item->property();
      auto decay_group = item->decayGroup();
      return prop.read(decay_group.get());
   }

   return QVariant();
}

bool ParameterListModel::setData(const QModelIndex & index, const QVariant & value, int role)
{
   if (role != Qt::EditRole)
      return false;

   int col = index.column();
   int changed = false;

   auto item = GetItem(index);
   auto parameter = item->parameter();

   if (item->type() == ParameterListItem::Group && col == 0)
   {
      item->decayGroup()->setObjectName(value.toString());
      changed = true;
   }
   else if (item->type() == ParameterListItem::Parameter)
   {
      if (col == 1)
      {
         parameter->initial_value = value.toDouble();
         changed = true;
      }
      else if (col == 2)
      {
         parameter->fitting_type = static_cast<ParameterFittingType>(value.toInt());
         changed = true;
      }
   }
   else if (item->type() == ParameterListItem::Option && index.column() == 1)
   {
      auto prop = item->property();
      auto decay_group = item->decayGroup();
      prop.write(decay_group.get(), value);
      changed = true;

      emit layoutAboutToBeChanged();
      GetItem(index.parent())->refresh();
      changePersistentIndex(index.parent(), index.parent());
      emit layoutChanged();
   }

   return changed;
}

Qt::ItemFlags ParameterListModel::flags(const QModelIndex & index) const
{
   Qt::ItemFlags flags = Qt::ItemIsSelectable | Qt::ItemIsEnabled;

   auto item = GetItem(index);

   if (item->type() == ParameterListItem::Group && index.column() == 0)
      flags |= Qt::ItemIsEditable;
   
   if ((item->type() == ParameterListItem::Parameter || 
       item->type() == ParameterListItem::Option) && (index.column() > 0))  
      flags |= Qt::ItemIsEditable;

   return flags;
}

int ParameterListModel::rowCount(const QModelIndex& parent) const
{
   ParameterListItem* parent_item = GetItem(parent);
   return parent_item->childCount();
}

int ParameterListModel::columnCount(const QModelIndex & parent) const
{
   return 3;
}

ParameterListItem* ParameterListModel::GetItem(const QModelIndex& parent) const
{
   ParameterListItem* parent_item;
   if (!parent.isValid())
      parent_item = root_item;
   else
      parent_item = static_cast<ParameterListItem*>(parent.internalPointer());
   return parent_item;
}

void ParameterListModel::removeGroup(const QModelIndex index)
{
   auto item = GetItem(index);
   if (item->type() == ParameterListItem::Group)
   {
      int row = index.row();

      beginRemoveRows(index.parent(), row, row);
      decay_model->removeDecayGroup(item->decayGroup());
      root_item->removeChild(row);
      endRemoveRows();
   }
}

void ParameterListModel::addGroup(int group_type)
{

   shared_ptr<AbstractDecayGroup> new_group;
   if (group_type == 0)
      new_group = std::make_shared<MultiExponentialDecayGroup>();
   else if (group_type == 1)
      new_group = std::make_shared<FretDecayGroup>();
   //else if (group_type == 2)
   //   new_group = std::make_shared<AnisotropyDecayGroup>();

   int row = root_item->childCount();
   beginInsertRows(createIndex(0, 0, root_item), row, row+1);
   decay_model->addDecayGroup(new_group);
   root_item->addChild(new ParameterListItem(new_group, row, root_item));
   endInsertRows();
}