package OMEuiUtils;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author imunro
 */
public class datasetInfo {
  
  private final String name;
  private final  Long Id;
  public Integer type;
  private Object obj;
    
    public datasetInfo(String name, Long Id, Integer type) {
      this.obj = null;
      this.name = name;
      this.Id = Id;
      this.type = type;
          
    }
    
    public void setObject(Object Obj)  {
      obj = Obj;
    }
    
    public Object getObject()  {
      return obj;
    }
    
    
    @Override
    public String toString() {
        return name;
    }
    
     public Integer getType() {
        return type;
    }
     
   
}
  


