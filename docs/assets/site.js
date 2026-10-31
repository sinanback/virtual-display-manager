// Optional illustration only. No hardware access, network calls or analytics.
document.querySelectorAll('[data-monitor]').forEach(button => {
  button.addEventListener('click', () => {
    const panel = button.closest('.diagram');
    const connected = button.dataset.monitor === 'on';
    const tr = panel.dataset.lang === 'tr';
    panel.querySelectorAll('[data-monitor]').forEach(b => b.setAttribute('aria-pressed', String(b === button)));
    panel.querySelector('#physical-state').textContent = connected ? (tr ? 'Bağlı' : 'Connected') : (tr ? 'Bağlı değil' : 'Disconnected');
    panel.querySelector('#physical-dot').className = 'dot ' + (connected ? 'on' : 'off');
    const state = panel.querySelector('#virtual-state');
    state.textContent = connected ? (tr ? 'KAPALI' : 'OFF') : (tr ? 'AÇIK' : 'ON');
    state.className = 'status ' + (connected ? 'off' : 'on');
    panel.querySelector('#virtual-note').textContent = connected ? (tr ? 'Fiziksel ekran kullanılıyor' : 'Physical display in use') : (tr ? 'Yakalanabilecek bir ekran kaynağı' : 'A screen available for capture');
  });
});
