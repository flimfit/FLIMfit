#pragma once

#include <QAbstractItemModel>
#include <QMetaProperty>
#include "DecayModel.h"

class ChannelFactorListItem
{
public:
   enum Type { Root, Group, Channel };
   
   ChannelFactorListItem(shared_ptr<QDecayModel> model);
   ChannelFactorListItem(shared_ptr<AbstractDecayGroup> group, ChannelFactorListItem* parent);
   ChannelFactorListItem(shared_ptr<AbstractDecayGroup> group, int index, ChannelFactorListItem* parent);

   ~ChannelFactorListItem();

   void refresh();

   int row() const;

   Type type() { return m_type; }
   ChannelFactorListItem* parent() { return m_parent; }
   ChannelFactorListItem* child(int row) { return m_children.value(row); }
   int childCount() { return m_children.size(); }

   const QString& name() { return m_name; }
   shared_ptr<AbstractDecayGroup> decayGroup() { return m_decay_group; }
   int decayGroupIndex() { return m_group_index; }

   void addChild(ChannelFactorListItem* child) { m_children.append(child); }
   
   void removeChild(int row) 
   { 
      delete m_children.at(row); 
      m_children.removeAt(row);
   }

protected:
   
   QString m_name;
   QList<ChannelFactorListItem*> m_children;
   Type m_type;
   ChannelFactorListItem* m_parent;
   int m_group_index;

   shared_ptr<AbstractDecayGroup> m_decay_group;
};

class ChannelFactorListModel : public QAbstractItemModel
{
   Q_OBJECT

public:
   ChannelFactorListModel(shared_ptr<QDecayModel> decay_model, QObject* parent = 0);
   ~ChannelFactorListModel();

   void parseDecayModel();

   void addGroup(int group_type);
   void removeGroup(const QModelIndex index);

   QModelIndex index(int row, int column, const QModelIndex & parent = QModelIndex()) const;
   QModelIndex parent(const QModelIndex & index) const;
   QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
   QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
   bool setData(const QModelIndex & index, const QVariant & value, int role = Qt::EditRole);
   Qt::ItemFlags flags(const QModelIndex & index) const;
   int rowCount(const QModelIndex& parent = QModelIndex()) const;
   int columnCount(const QModelIndex & parent = QModelIndex()) const;


protected:

   ChannelFactorListItem* GetItem(const QModelIndex& parent) const;

   shared_ptr<QDecayModel> decay_model;
   ChannelFactorListItem *root_item;
};