import QtQuick

QtObject {
 property var entries:[]
 property int index:-1
 function persist(){
  let bounded=entries.slice(-32).map(row=>({id:row.id,path:row.path,title:row.title,type:row.type,source_kind:row.source_kind,vault:row.vault,vault_id:row.vault_id,surface:row.surface,_view:row._view||{}}));
  let layouts=Object.assign({},NoesisController.layouts);
  layouts["navigation-v1"]={version:1,entries:bounded,index:Math.max(-1,index-(entries.length-bounded.length))};
  NoesisController.layouts=layouts;
 }
 function restore(){
  let stored=NoesisController.layouts["navigation-v1"];
  if(stored?.version!==1||!Array.isArray(stored.entries))return;
  entries=stored.entries.slice(-32).filter(row=>typeof row.id==="string"&&typeof row.vault==="string");
  index=Math.max(-1,Math.min(entries.length-1,stored.index??entries.length-1));
 }
}
