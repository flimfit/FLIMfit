package OMEuiUtils;


import java.awt.Component;
import javax.swing.JTree;
import javax.swing.tree.DefaultTreeCellRenderer;
import javax.swing.tree.DefaultMutableTreeNode;
import javax.swing.ImageIcon;
import javax.swing.Icon;



/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author imunro
 */
  
public class customCellRenderer extends DefaultTreeCellRenderer {
    
    private Icon typeIcons[]; 
    
    
    @Override
    public Component getTreeCellRendererComponent(JTree tree, Object value,
        boolean sel, boolean expanded, boolean leaf, int row, boolean hasFocus) {

      super.getTreeCellRendererComponent(tree, value, sel, expanded, leaf, row,
          hasFocus);
      
      DefaultMutableTreeNode node = (DefaultMutableTreeNode)value;  
 
      if (node.getUserObject() instanceof datasetInfo) {
        datasetInfo info  = (datasetInfo)node.getUserObject();
        setIcon(typeIcons[info.type]);
        
      }
     
         
      
      return this;
    }
      
    //public void setIcons (ImageIcon ic[])  {
    public void setIcons()  {
     
     
      typeIcons = new ImageIcon[6];
      ImageIcon ic;
      ic = new ImageIcon(getClass().getResource("Resources/nuvola_kdmconfig_modified16.png"));
      typeIcons[5] = ic;
      ImageIcon ic1;
      ic1 = new ImageIcon(getClass().getResource("Resources/nuvola_folder_darkblue_open16.png"));
      typeIcons[3] = ic1;
      ImageIcon ic2;
      ic2 = new ImageIcon(getClass().getResource("Resources/nuvola_folder_image16.png"));
      typeIcons[1] = ic2;
      ImageIcon ic3;
      ic3 = new ImageIcon(getClass().getResource("Resources/nuvola_image16.png"));
      typeIcons[0] = ic3;  
      ImageIcon ic4;
      ic4 = new ImageIcon(getClass().getResource("Resources/plate16.png"));
      typeIcons[2] = ic4;
      ImageIcon ic5;
      ic5 = new ImageIcon(getClass().getResource("Resources/nuvola_folder_blue_open_modified_screen16.png"));
      typeIcons[4] = ic5;
                         
      
      //typeIcons = new ImageIcon[ic.length];
      //for(int  i = 0; i< ic.length; i++)  {
      //  typeIcons[i] = ic[i];
      //}
    }
      
}
