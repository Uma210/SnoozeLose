/* SnoozeLose v1.7 home controller: native alarm bridge + Pebble presentation only. */
(()=>{'use strict';
 const $=id=>document.getElementById(id);
 const frame=$('pet-frame');
 const hero=$('hero');
 const controls=[...document.querySelectorAll('[data-pet]')];
 let toastTimer=null;
 let muted=false;
 function toast(message){const n=$('home-toast');n.textContent=message;n.hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>{n.hidden=true},2800)}
 function command(command,value){if(!frame?.contentWindow)return;frame.contentWindow.postMessage({kind:'snoozelose-pebble',command,value},'*')}
 // A blocked local iframe should not leave an invisible penguin without feedback.
 frame?.addEventListener('error',()=>toast('Pebble could not load. Alarm controls are still available.'));
 const settings=$('pet-dialog');
 const help=$('help-dialog');
 function modalOpen(dialog){if(!dialog.open){dialog.showModal();}}
 document.querySelectorAll('[data-close]').forEach(btn=>btn.addEventListener('click',()=>$(btn.dataset.close).close()));
 for(const d of [help,settings])d.addEventListener('click',event=>{if(event.target===d)d.close()});
 $('learn-how').addEventListener('click',()=>modalOpen(help));
 controls.forEach(btn=>btn.addEventListener('click',()=>{
   const action=btn.dataset.pet;
   if(action==='settings'){modalOpen(settings);return;}
   command(action);
   btn.classList.add('playing');setTimeout(()=>btn.classList.remove('playing'),350);
   if(action==='mic'){toast('Microphone permission may be required. Audio remains on your device.');}
 }));
 const fields={pitch:'pet-pitch',volume:'pet-volume',sensitivity:'pet-sensitivity'};
 const form={pitch:1.7,volume:80,sensitivity:.028};
 function adjust(name,val){form[name]=val;const n=$(fields[name]);
   if(name==='pitch')$('pet-pitch-value').value=Number(val).toFixed(1)+'×';
   if(name==='volume')$('pet-volume-value').value=Math.round(Number(val))+'%';
   if(name==='sensitivity')$('pet-sensitivity-value').value=Number(val)<.022?'High':Number(val)>.048?'Low':'Normal';
   command('configure',{[name]:Number(val)});
 }
 Object.keys(fields).forEach(name=>$(fields[name]).addEventListener('input',e=>adjust(name,e.target.value)));
 $('pet-mute').addEventListener('click',()=>{muted=!muted;command('mute');$('pet-mute').setAttribute('aria-pressed',String(muted));$('pet-mute').textContent=muted?'Unmute Pebble sounds':'Mute Pebble sounds'});
 frame.addEventListener('load',()=>command('configure',form));
 window.addEventListener('message',event=>{
   if(event.source!==frame.contentWindow||event.data?.kind!=='pebble-status')return;
   if(typeof event.data.micEnabled==='boolean'){
     const mic=document.querySelector('[data-pet="mic"]');
     mic.setAttribute('aria-pressed',String(event.data.micEnabled));
     mic.setAttribute('aria-label',event.data.micEnabled?'Turn off microphone repeat back':'Turn on microphone repeat back');
   }
 });
 window.snoozeStopPebble=()=>command('stop');
 function nativeAction(action){
   if(window.webkit?.messageHandlers?.snooze){window.webkit.messageHandlers.snooze.postMessage(action)}
   else toast('Open the SnoozeLose iPhone app to manage alarms.');
 }
 document.querySelectorAll('[data-native]').forEach(btn=>btn.addEventListener('click',()=>nativeAction(btn.dataset.native)));
 document.addEventListener('visibilitychange',()=>{if(document.hidden)window.snoozeStopPebble()});
 window.addEventListener('pagehide',window.snoozeStopPebble);
 // Draw fog only during active touch/drag interaction. Static haze requires no rendering loop.
 const canvas=$('tide-fog'),ctx=canvas.getContext('2d');
 const reduced=matchMedia('(prefers-reduced-motion: reduce)');
 let points=[],fogFrame=0;
 function size(){const r=hero.getBoundingClientRect();const pixelRatio=Math.min(window.devicePixelRatio||1,2);canvas.width=Math.ceil(r.width*pixelRatio);canvas.height=Math.ceil(r.height*pixelRatio);ctx.setTransform(pixelRatio,0,0,pixelRatio,0,0)}
 size();window.addEventListener('resize',size,{passive:true});
 function draw(time){fogFrame=0;const w=canvas.clientWidth,h=canvas.clientHeight;ctx.clearRect(0,0,w,h);points=points.filter(p=>time-p.t<1200);if(!points.length)return;
   ctx.fillStyle='rgba(255,255,255,.24)';ctx.fillRect(0,0,w,h);ctx.globalCompositeOperation='destination-out';
   for(const p of points){const age=Math.min(1,(time-p.t)/1200);const r=75+age*85;const g=ctx.createRadialGradient(p.x,p.y,0,p.x,p.y,r);g.addColorStop(0,`rgba(0,0,0,${1-age})`);g.addColorStop(1,'rgba(0,0,0,0)');ctx.fillStyle=g;ctx.beginPath();ctx.arc(p.x,p.y,r,0,Math.PI*2);ctx.fill()}
   ctx.globalCompositeOperation='source-over';fogFrame=requestAnimationFrame(draw);
 }
 hero.addEventListener('pointermove',event=>{if(reduced.matches||document.hidden)return;
   const r=hero.getBoundingClientRect();points.push({x:event.clientX-r.left,y:event.clientY-r.top,t:performance.now()});if(points.length>9)points.shift();if(!fogFrame)fogFrame=requestAnimationFrame(draw);
 },{passive:true});
 document.addEventListener('visibilitychange',()=>{if(document.hidden){cancelAnimationFrame(fogFrame);fogFrame=0;points=[];ctx.clearRect(0,0,canvas.clientWidth,canvas.clientHeight)}});
})();
