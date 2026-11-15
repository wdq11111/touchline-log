/* Touchline Log i18n: translates UI text nodes and attributes from English using lang/<code>.json.
   Keys are the English strings; keys containing {name} placeholders are templates. */
(function(){
  const LANGS=[['en','English'],['zh-CN','简体中文'],['zh-TW','繁體中文'],['es','Español'],['pt-BR','Português (Brasil)'],['fr','Français'],['de','Deutsch'],['it','Italiano'],['id','Bahasa Indonesia'],['vi','Tiếng Việt'],['th','ไทย'],['tr','Türkçe'],['ar','العربية'],['ru','Русский'],['ja','日本語'],['ko','한국어']];
  const RTL=['ar'];const ATTRS=['placeholder','aria-label','title','alt'];
  let lang='en',dict={},tpls=[];
  const esc=s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
  function compile(){tpls=Object.keys(dict).filter(k=>k.includes('{')).map(k=>{const names=[];const re=new RegExp('^'+esc(k).replace(/\\\{(\w+)\\\}/g,(m,n)=>{names.push(n);return /^n\d?$/.test(n)?'(-?[\\d.,]+)':'(.+?)'})+'$');return{re,names,out:dict[k]}})}
  function tr(s){
    if(lang==='en'||!s)return s;
    const t=s.trim();if(!t)return s;
    let out=dict[t];
    if(out==null){for(const p of tpls){const m=t.match(p.re);if(m){out=p.out.replace(/\{(\w+)\}/g,(x,n)=>{const i=p.names.indexOf(n);return i<0?x:m[i+1]});break}}}
    if(out==null)return s;
    const a=s.indexOf(t);return s.slice(0,a)+out+s.slice(a+t.length);
  }
  function fmt(s,p){return tr(s).replace(/\{(\w+)\}/g,(x,n)=>p&&n in p?p[n]:x)}
  function doText(n){
    if(n.__tr!==undefined&&n.nodeValue===n.__tr)return;
    n.__en=n.nodeValue;const v=tr(n.__en);n.__tr=v;if(v!==n.nodeValue)n.nodeValue=v;
  }
  function doAttrs(el){
    for(const a of ATTRS){if(!el.hasAttribute(a))continue;el.__ena=el.__ena||{};el.__tra=el.__tra||{};const cur=el.getAttribute(a);
      if(el.__tra[a]!==cur)el.__ena[a]=cur;const v=tr(el.__ena[a]);el.__tra[a]=v;if(v!==cur)el.setAttribute(a,v)}
  }
  const SKIP={SCRIPT:1,STYLE:1,TEXTAREA:1};
  function walk(root){
    if(root.nodeType===3){if(!root.parentNode||!SKIP[root.parentNode.nodeName])doText(root);return}
    if(root.nodeType!==1||SKIP[root.nodeName])return;
    if(root.closest&&root.closest('[data-notr]'))return;
    doAttrs(root);
    const w=document.createTreeWalker(root,NodeFilter.SHOW_ELEMENT|NodeFilter.SHOW_TEXT,{acceptNode:n=>n.nodeType===1?(n.hasAttribute('data-notr')?NodeFilter.FILTER_REJECT:SKIP[n.nodeName]?(n.nodeName==='TEXTAREA'&&doAttrs(n),NodeFilter.FILTER_REJECT):NodeFilter.FILTER_ACCEPT):(SKIP[n.parentNode.nodeName]?NodeFilter.FILTER_REJECT:NodeFilter.FILTER_ACCEPT)});
    let n;while((n=w.nextNode())){if(n.nodeType===3)doText(n);else doAttrs(n)}
  }
  function reset(root){
    const w=document.createTreeWalker(root,NodeFilter.SHOW_ELEMENT|NodeFilter.SHOW_TEXT);let n=root;
    do{if(n.nodeType===3&&n.__en!==undefined&&n.nodeValue===n.__tr){n.nodeValue=n.__en;n.__tr=undefined}
      else if(n.nodeType===1&&n.__ena){for(const a in n.__ena){if(n.getAttribute(a)===n.__tra[a])n.setAttribute(a,n.__ena[a])}n.__ena=n.__tra=null}}while((n=w.nextNode()));
  }
  const mo=new MutationObserver(ms=>{for(const m of ms){
    if(m.type==='characterData')walk(m.target);
    else if(m.type==='attributes')doAttrs(m.target);
    else m.addedNodes.forEach(walk)}});
  function pick(){
    let saved=null;try{saved=localStorage.getItem('touchline-lang')}catch(e){}
    if(saved&&LANGS.some(l=>l[0]===saved))return saved;
    for(const nl of navigator.languages||[navigator.language||'en']){const l=nl.toLowerCase();
      if(l.startsWith('zh'))return /tw|hk|mo|hant/.test(l)?'zh-TW':'zh-CN';
      if(l.startsWith('pt'))return 'pt-BR';
      const hit=LANGS.find(x=>x[0]===l.split('-')[0]);if(hit)return hit[0]}
    return 'en';
  }
  async function setLang(code,remember){
    let d={};
    if(code!=='en'){try{const r=await fetch('lang/'+code+'.json',{cache:'force-cache'});if(!r.ok)throw 0;d=await r.json()}catch(e){code='en';d={}}}
    reset(document.body);lang=code;dict=d;compile();
    document.documentElement.lang=code;document.documentElement.dir=RTL.includes(code)?'rtl':'ltr';
    if(remember){try{localStorage.setItem('touchline-lang',code)}catch(e){}}
    const sel=document.getElementById('lang');if(sel)sel.value=code;
    walk(document.body);
    window.dispatchEvent(new Event('tl-lang'));
  }
  window.TL_i18n={t:fmt,lang:()=>lang,setLang,LANGS};
  function start(){
    const sel=document.getElementById('lang');
    if(sel){sel.innerHTML=LANGS.map(([c,n])=>`<option value="${c}">${n}</option>`).join('');sel.setAttribute('data-notr','');sel.onchange=()=>setLang(sel.value,true)}
    mo.observe(document.body,{childList:true,subtree:true,characterData:true,attributes:true,attributeFilter:ATTRS});
    setLang(pick(),false);
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start);else start();
})();
