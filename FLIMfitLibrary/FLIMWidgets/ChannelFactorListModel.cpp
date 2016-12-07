#include "ChannelFactorListModel.h"
#include "MultiExponentialDecayGroup.h"
#include "FretDecayGroup.h"
#include "AnisotropyDecayGroup.h"
#include <QMetaProperty>

ChannelFactorListItem::ChannelFactorListItem(shared_ptr<QDecayModel> model)
{
   m_type = Root;
   m_parent = nullptr;

   int n_groups = model->getNumGroups();

   for (int i = 0; i < n_groups; i++)
      m_children.append(new ChannelFactorListItem(model->getGroup(i), this));
}

ChannelFactorListItem::ChannelFactorListItem(shared_ptr<AbstractDecayGroup> group, ChannelFactorListItem* parent)
{
   m_type = Group;
   m_parent = parent;
   m_name = group->objectName();
   m_decay_group = group;

   const vector<std::string>& channel_factor_names = group->getChannelFactorNames();

   if (channel_factor_names.size() > 0)
   {
      for (int i = 0; i < channel_factor_names.size(); i++)
      {
         auto s = channel_factor_names[i];
         m_children.append(new ChannelFactorListItem(group, i, this));
      }
      m_group_index = -1;
   }
   else
   {
      m_group_index = 0;
   }
}

ChannelFactorListItem::ChannelFactorListItem(shared_ptr<AbstractDecayGroup> group, int index, ChannelFactorListItem* parent)
{
   m_type = Channel;
   m_parent = parent;
   m_name = QString::fromStdString(group->getChannelFactorNames()[index]);
   m_decay_group = group;
   m_group_index = index;
}

ChannelFactorListItem::~ChannelFactorListItem()
{
   qDeleteAll(m_children);
}

int ChannelFactorListItem::row() const
{
   if (m_parent)
      return m_parent->m_children.indexOf(const_cast<ChannelFactorListItem*>(this));

   return 0;
}

ChannelFactorListModel::ChannelFactorListModel(shared_ptr<QDecayModel> decay_model, QObject* parent) :
   QAbstractItemModel(parent),
   decay_model(decay_model)
{
   connect(decay_model.get(), &QDecayModel::groupsUpdated, this, &ChannelFactorListModel::parseDecayModel, Qt::QueuedConnection);
   root_item = new ChannelFactorListItem(decay_model);
}


void ChannelFactorListModel::parseDecayModel()
{
   beginResetModel();
   delete root_item;
   root_item = new ChannelFactorListItem(decay_model);
   endResetModel();
}

ChannelFactorListModel::~ChannelFactorListModel()
{
   delete root_item;
}

QModelIndex ChannelFactorListModel::index(int row, int column, const QModelIndex & parent) const
{
   if (!hasIndex(row, column, parent))
      return QModelIndex();

   ChannelFactorListItem *parent_item = GetItem(parent);

   ChannelFactorListItem *childItem = parent_item->child(row);
   if (childItem)
      return createIndex(row, column, childItem);
   else
      return QModelIndex();
}

QModelIndex ChannelFactorListModel::parent(const QModelIndex & index) const
{
   if (!index.isValid())
      return QModelIndex();

   ChannelFactorListItem *child_item = static_cast<ChannelFactorListItem*>(index.internalPointer());
   ChannelFactorListItem *parent_item = child_item->parent();

   if (parent_item == root_item)
      return QModelIndex();

   return createIndex(parent_item->row(), 0, parent_item);
}

QVariant ChannelFactorListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
   if (role != Qt::DisplayRole)
      return QVariant();

   if (orientation == Qt::Orientation::Horizontal)
   {
      if (section == 0)
         return "Group";
      else
         return QString("Ch.%1").arg(section);
   }

   return QVariant();
}

QVariant ChannelFactorListModel::data(const QModelIndex & index, int role) const
{
   if (role != Qt::DisplayRole && role != Qt::EditRole)
      return QVariant();

   auto item = GetItem(index);

   if (!index.isValid())
      return QVariant();

   if (index.column() == 0)
   {
      if (item->type() == ChannelFactorListItem::Group)
         return item->decayGroup()->objectName();
      else
         return item->name();
   }

   if (item->decayGroupIndex() >= 0)
   {
      auto decay_group = item->decayGroup();
      auto& channel_factors = decay_group->getChannelFactors(item->decayGroupIndex());
      if (index.column() <= channel_factors.size())
         return channel_factors[index.column() - 1];
   }

   return QVariant();
}

bool ChannelFactorListModel::setData(const QModelIndex & index, const QVariant & value, int role)
{
   if (role != Qt::EditRole)
      return false;

   int changed = false;

   auto item = GetItem(index);

   if (item->decayGroupIndex() >= 0)
   {
      auto decay_group = item->decayGroup();
      int i = item->decayGroupIndex();
      vector<double> channel_factors = decay_group->getChannelFactors(i);
      channel_factors[index.column() - 1] = value.toDouble();
      decay_group->setChannelFactors(i, channel_factors);
      changed = true;
   }

   return changed;
}

Qt::ItemFlags ChannelFactorListModel::flags(const QModelIndex & index) const
{
   Qt::ItemFlags flags = Qt::ItemIsSelectable | Qt::ItemIsEnabled;

   auto item = GetItem(index);

   if (item->decayGroupIndex() >= 0 && index.column() > 0)
      flags |= Qt::ItemIsEditable;

   return flags;
}

int ChannelFactorListModel::rowCount(const QModelIndex& parent) const
{
   ChannelFactorListItem* parent_item = GetItem(parent);
   return parent_item->childCount();
}

int ChannelFactorListModel::columnCount(const QModelIndex & parent) const
{
   return 1 + decay_model->getTransformedDataParameters()->n_chan;
}

ChannelFactorListItem* ChannelFactorListModel::GetItem(const QModelIndex& parent) const
{
   ChannelFactorListItem* parent_item;
   if (!parent.isValid())
      parent_item = root_item;
   else
      parent_item = static_cast<ChannelFactorListItem*>(parent.internalPointer());
   return parent_item;
}

void ChannelFactorListModel::removeGroup(const QModelIndex index)
{
   auto item = GetItem(index);
   if (item->type() == ChannelFactorListItem::Group)
   {
      int row = index.row();

      beginRemoveRows(index.parent(), row, row);
      decay_model->removeDecayGroup(item->decayGroup());
      root_item->removeChild(row);
      endRemoveRows();
   }
}

void ChannelFactorListModel::addGroup(int group_type)
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
   root_item->addChild(new ChannelFactorListItem(new_group, row, root_item));
   endInsertRows();
}