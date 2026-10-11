.pragma library
// Normalize pushed D-Bus data. Unknown charge and disconnected devices are absent.
function address(value) {return String(value||'').replace(/dev_/,'').replace(/_/g,':').match(/[0-9a-f]{2}(?::[0-9a-f]{2}){5}/i)?.[0]?.toLowerCase()||'';}
function rows(phones, bluetooth, upower) {
 const result=[],seen=new Set(),names=new Set();
 function add(row){if(seen.has(row.id))return;seen.add(row.id);names.add(row.name.toLowerCase());result.push(row);}
 for(const d of phones||[]){const charge=d.battery?.charge;if(d.isPaired&&d.isReachable&&Number.isFinite(charge)&&charge>=0&&charge<=100)add({id:'phone:'+d.id,name:d.name||'Phone',percent:charge,kind:'phone',phoneId:d.id,state:d.battery.isCharging?'Charging':'On battery',detail:'KDE Connect · live report'});}
 for(const d of bluetooth||[]){if(!d.connected||!d.batteryAvailable||!Number.isFinite(d.battery))continue;if(d.icon==='phone'&&result.some(r=>r.kind==='phone'&&r.name.toLowerCase()===(d.name||'').toLowerCase()))continue;add({id:address(d.address)||d.address,name:d.name||d.deviceName||'Bluetooth device',percent:Math.max(0,Math.min(100,d.battery*100)),kind:'bluetooth',state:'Connected',detail:'Bluetooth battery report'});}
 for(const d of upower||[]){if(!d.ready||d.isLaptopBattery||d.type<=1||d.iconName?.includes('missing')||!Number.isFinite(d.percentage))continue;
  const id=address(d.nativePath),known=(bluetooth||[]).find(b=>address(b.address)===id&&id);
  if(known&&!known.connected)continue;
  // UPower presence is defined only for battery packs, not mice/UPS.
  // A Bluetooth address must have a connected BlueZ peer.
  if(!known&&(id||(d.type===2&&!d.isPresent)))continue;
  const name=known?.name||d.model||'Battery device';if(names.has(name.toLowerCase()))continue;
  const parts=[];if(d.energyCapacity>0)parts.push(d.energy.toFixed(1)+' / '+d.energyCapacity.toFixed(1)+' Wh');if(d.healthSupported)parts.push(Math.round(d.healthPercentage*100)+'% health');
  add({id:id||d.nativePath||name,name:name,percent:Math.max(0,Math.min(100,d.percentage*100)),kind:known?'bluetooth':'peripheral',state:known?'Connected':'Present',detail:parts.join(' · ')||'UPower battery report'});
 }
 return result;
}
