const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const html = fs.readFileSync(require('node:path').join(__dirname, '../learning-path.html'), 'utf8');
const script = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].at(-1)[1];
function page(initial, unavailable = false) {
  let stored = initial;
  const note = {textContent:''};
  const cards = Array.from({length:8}, (_,i) => {
    const badge = {textContent:''};
    const checkbox = {checked:false, getAttribute:()=>String(i), addEventListener:(event,handler)=>{checkbox.change=handler;}};
    return {badge, checkbox, classList:{add(){},remove(){}}, querySelector:s=>s==='.step-status'?badge:checkbox};
  });
  let ready;
  const document = {
    querySelector: s=>cards[Number(s.match(/data-step="(\d+)"/)[1])],
    querySelectorAll: ()=>cards.map(c=>c.checkbox), getElementById:()=>note,
    addEventListener:(event,handler)=>{ready=handler;}
  };
  const localStorage = {
    getItem:()=>{if(unavailable)throw Error('blocked');return stored;},
    setItem:(_key,value)=>{if(unavailable)throw Error('blocked');stored=value;}
  };
  vm.runInNewContext(script,{window:{localStorage},document});
  ready();
  return {cards,note,stored:()=>stored,toggle(i,checked){const box=cards[i].checkbox;box.checked=checked;box.change({target:box});}};
}
const fresh = page(null);
assert.equal(fresh.cards[0].badge.textContent,'次の候補');
assert.equal(fresh.cards.filter(c=>c.checkbox.checked).length,0);
fresh.toggle(0,true);
assert.equal(fresh.cards[0].badge.textContent,'自己確認済み');
assert.equal(page(fresh.stored()).cards[0].checkbox.checked,true);
fresh.toggle(0,false);
assert.equal(fresh.cards[0].badge.textContent,'次の候補');
const blocked=page(null,true);
blocked.toggle(0,true);blocked.toggle(1,true);
assert.equal(blocked.cards[0].checkbox.checked,true);
assert.equal(blocked.cards[1].badge.textContent,'自己確認済み');
assert.match(blocked.note.textContent,/保存できません/);
const malformed=page('{bad json');
assert.equal(malformed.cards[0].badge.textContent,'次の候補');
assert.equal(page('{"0":"true","1":true}').cards[0].checkbox.checked,false);
console.log('PASS: fresh, toggle, reload, undo, unavailable storage, malformed storage, strict boolean states. This is UI logic verification, not learner or server evidence.');
