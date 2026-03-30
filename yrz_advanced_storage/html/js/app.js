// ============================================================
//  ox_stash_store | APP.JS  (v2 - fixed)
// ============================================================

'use strict';

let currentShopPoint = null;
let currentProduct   = null;
let productUnitPrice = 0;
let currentStashPoint = null;
let currentTransferItem = null;
let currentTransferDirection = null; // 'withdraw' or 'deposit'
let currentTransferMax = 0;
let imageConfig = { basePath: 'images/', defaultImage: 'default.png' };
let uiColors = {}; // Colores dinámicos desde config.lua

// ─── APLICAR TEMA (Inyectar variables CSS dinámicamente) ─────
function applyTheme(colors) {
    if (!colors || typeof colors !== 'object') return;
    
    uiColors = colors;
    
    // Crear nodo style dinámico
    let styleNode = document.getElementById('dynamic-theme-style');
    if (!styleNode) {
        styleNode = document.createElement('style');
        styleNode.id = 'dynamic-theme-style';
        document.head.appendChild(styleNode);
    }
    
    // Construir variables CSS
    let css = ':root {\n';
    
    // Colores primarios
    if (colors.primaryAccent) {
        css += `    --accent: ${colors.primaryAccent};\n`;
        css += `    --accent-glow: rgba(${hexToRgb(colors.primaryAccent)}, 0.4);\n`;
        css += `    --accent-dim: rgba(${hexToRgb(colors.primaryAccent)}, 0.15);\n`;
        css += `    --shadow-glow: 0 0 20px var(--accent-glow);\n`;
        css += `    --accent-shop: ${colors.primaryAccent};\n`;
        css += `    --accent-shop-dim: rgba(${hexToRgb(colors.primaryAccent)}, 0.15);\n`;
        css += `    --accent-stash: ${colors.primaryAccent};\n`;
        css += `    --accent-stash-dim: rgba(${hexToRgb(colors.primaryAccent)}, 0.15);\n`;
    }
    
    // Colores de bordes
    if (colors.borderPrimaryColor) {
        const borderOpacity = (colors.borderOpacity !== undefined) ? colors.borderOpacity : 0.2;
        css += `    --border: rgba(${hexToRgb(colors.borderPrimaryColor)}, ${borderOpacity});\n`;
        css += `    --border-shop: rgba(${hexToRgb(colors.borderPrimaryColor)}, ${borderOpacity + 0.05});\n`;
        css += `    --border-stash: rgba(${hexToRgb(colors.borderPrimaryColor)}, ${borderOpacity + 0.05});\n`;
    }
    
    // Colores de estado
    if (colors.success) css += `    --accent-green: ${colors.success};\n`;
    if (colors.error) css += `    --accent-red: ${colors.error};\n`;
    if (colors.textPrimary) css += `    --text-primary: ${colors.textPrimary};\n`;
    if (colors.textSecondary) css += `    --text-secondary: ${colors.textSecondary};\n`;
    
    css += '}\n';
    
    styleNode.textContent = css;
}

// ─── Helper: Convertir hex a RGB ────────────────────────────
function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) return '0, 212, 255'; // Default cyan
    return `${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}`;
}

// ─── NUI → Lua (fire and forget, sin await en callbacks) ────
const resourceName = GetParentResourceName();
function nuiPost(endpoint, data) {
    fetch(`https://${resourceName}/${endpoint}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data ?? {}),
    }).catch(() => {});
}

// ─── Mensajes desde Lua ─────────────────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'openShop':
            if (d.imageConfig) imageConfig = d.imageConfig;
            if (d.uiColors) applyTheme(d.uiColors);
            openShop(d.point, d.products);
            break;
        case 'openStash':
            if (d.imageConfig) imageConfig = d.imageConfig;
            if (d.uiColors) applyTheme(d.uiColors);
            openStash(d.point, d.stash, d.player);
            break;
        case 'updateStash':
            if (d.imageConfig) imageConfig = d.imageConfig;
            if (d.uiColors) applyTheme(d.uiColors);
            updateStash(d.stash, d.player);
            break;
        case 'openAdmin':
            if (d.uiColors) applyTheme(d.uiColors);
            openAdmin(d.points, d.playerCoords);
            break;
        case 'refreshAdminPoints':
            // El servidor actualizó puntos mientras el panel estaba abierto
            if (typeof allPoints !== 'undefined') {
                allPoints    = d.points    || [];
                playerCoords = d.playerCoords || playerCoords;
                renderAllTabs();
            }
            break;
    }
});

// ─── TOAST ──────────────────────────────────────────────────
function showToast(msg, type = 'info') {
    const icons = { success: '✅', error: '❌', info: 'ℹ️' };
    const el = document.createElement('div');
    el.className = `toast toast-${type}`;
    el.innerHTML = `<span>${icons[type] || 'ℹ️'}</span><span>${msg}</span>`;
    document.getElementById('toast-container').appendChild(el);
    setTimeout(() => el.remove(), 3000);
}

// ─── SHOP ────────────────────────────────────────────────────
function openShop(point, products) {
    currentShopPoint = point;
    document.getElementById('shop-title').textContent = point?.name || 'Tienda';
    renderProducts(products || []);
    const overlay = document.getElementById('shop-overlay');
    overlay.classList.remove('hidden', 'hiding');
    overlay.querySelector('.panel')?.classList.remove('hiding');
}

function animateCloseOverlay(overlayId) {
    const overlay = document.getElementById(overlayId);
    if (!overlay || overlay.classList.contains('hidden')) return;
    const panel = overlay.querySelector('.panel, .modal');

    overlay.classList.add('hiding');
    if (panel) panel.classList.add('hiding');

    const onEnd = () => {
        overlay.classList.remove('hiding');
        overlay.classList.add('hidden');
        if (panel) panel.classList.remove('hiding');
        overlay.removeEventListener('animationend', onEnd);
    };

    overlay.addEventListener('animationend', onEnd);
}

function closeShop() {
    animateCloseOverlay('shop-overlay');
    animateCloseOverlay('qty-overlay');
    currentShopPoint = null;
    currentProduct   = null;
    nuiPost('closeUI');
}

function getImageSRC(imageKey) {
    if (!imageKey || imageKey === '') {
        // Devolver la URL por defecto desde ox_inventory
        return (imageConfig.basePath || 'nui://ox_inventory/web/images/') + (imageConfig.defaultImage || 'default.png');
    }
    
    // Si ya es una URL completa, devolverla tal cual
    if (imageKey.startsWith('http://') || imageKey.startsWith('https://') || imageKey.startsWith('nui://') || imageKey.startsWith('/')) {
        return imageKey;
    }
    
    // Construir URL concatenando
    return (imageConfig.basePath || 'nui://ox_inventory/web/images/') + imageKey;
}

function renderProducts(products) {
    const grid = document.getElementById('shop-products');
    grid.innerHTML = '';
    if (!products.length) {
        grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1">
            <span class="empty-icon">📭</span><span>Sin productos disponibles</span></div>`;
        return;
    }
    products.forEach(prod => {
        const card = document.createElement('div');
        card.className = 'product-card';
        card.innerHTML = `
            <img src="${getImageSRC(prod.image)}" class="product-image" alt="${prod.label}" onerror="this.onerror=null;this.src='images/default.png';">
            <div class="product-name">${escHtml(prod.label)}</div>
            <div class="product-item">${escHtml(prod.item_name)}</div>
            <div class="product-price">${Number(prod.price).toLocaleString()}</div>`;
        card.addEventListener('click', () => openQtyModal(prod));
        grid.appendChild(card);
    });
}

// ─── QTY MODAL ──────────────────────────────────────────────
function openQtyModal(prod) {
    currentProduct   = prod;
    productUnitPrice = prod.price;
    document.getElementById('qty-title').textContent    = prod.label;
    document.getElementById('qty-subtitle').textContent = `Precio unitario: $${prod.price}`;
    document.getElementById('qty-input').value          = 1;
    updateQtyTotal();
    const overlay = document.getElementById('qty-overlay');
    overlay.classList.remove('hidden', 'hiding');
    overlay.querySelector('.modal')?.classList.remove('hiding');
}

function closeQtyModal() {
    animateCloseOverlay('qty-overlay');
    currentProduct = null;
}

function changeQty(delta) {
    const inp = document.getElementById('qty-input');
    let v = Math.max(1, Math.min(999, (parseInt(inp.value) || 1) + delta));
    inp.value = v;
    updateQtyTotal();
}

document.getElementById('qty-input').addEventListener('input', updateQtyTotal);
const stashQtyInput = document.getElementById('stash-qty-input');
if (stashQtyInput) {
    stashQtyInput.addEventListener('input', () => {
        let value = Math.max(1, parseInt(stashQtyInput.value) || 1);
        stashQtyInput.value = value;
    });
}

function updateQtyTotal() {
    const qty = parseInt(document.getElementById('qty-input').value) || 1;
    document.getElementById('qty-total').textContent = `Total: $${(qty * productUnitPrice).toLocaleString()}`;
}

// ─── STASH FUNCTIONS ────────────────────────────────────────
function openStash(point, stashInv, playerInv) {
    currentStashPoint = point;
    document.getElementById('stash-title').textContent = point && point.name ? point.name : 'Almacén';
    renderStashItems(stashInv || { items: [] });
    renderPlayerItems(playerInv || { items: [] });
    const overlay = document.getElementById('stash-overlay');
    overlay.classList.remove('hidden', 'hiding');
    overlay.querySelector('.panel')?.classList.remove('hiding');
}

function updateStash(stashInv, playerInv) {
    renderStashItems(stashInv || { items: [] });
    renderPlayerItems(playerInv || { items: [] });
}

function closeStash() {
    animateCloseOverlay('stash-overlay');
    currentStashPoint = null;
    nuiPost('closeUI');
}

function closeStashQtyModal() {
    animateCloseOverlay('stash-qty-overlay');
    currentTransferItem = null;
    currentTransferDirection = null;
    currentTransferMax = 0;
}

function renderStashItems(inventory) {
    const grid = document.getElementById('stash-items');
    grid.innerHTML = '';
    const items = Array.isArray(inventory && inventory.items) ? inventory.items : [];
    if (!items.length) {
        grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1"><span class="empty-icon">📪</span><span>Almacén vacío</span></div>`;
        return;
    }

    items.forEach(item => {
        if (!item) return;
        const count = item.count != null ? item.count : (item.amount != null ? item.amount : (item.quantity != null ? item.quantity : 0));
        if (count <= 0) return;

        const card = document.createElement('div');
        card.className = 'stash-item';
        const imageName = item.image && item.image !== '' ? item.image : `${item.name}.png`;
        card.innerHTML = `
            <img src="${getImageSRC(imageName)}" class="item-image" alt="${item.label}" onerror="this.onerror=null;this.src='images/default.png';">
            <div class="item-name">${escHtml(item.label || item.name || 'Desconocido')}</div>
            <div class="item-count">${count}</div>`;
        card.addEventListener('click', () => openMoveModal(item, 'withdraw', count));
        grid.appendChild(card);
    });
}

function renderPlayerItems(inventory) {
    const grid = document.getElementById('player-items');
    grid.innerHTML = '';
    const items = Array.isArray(inventory && inventory.items) ? inventory.items : [];
    if (!items.length) {
        grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1"><span class="empty-icon">🎒</span><span>Tu inventario está vacío</span></div>`;
        return;
    }

    items.forEach(item => {
        if (!item) return;
        const count = item.count != null ? item.count : (item.amount != null ? item.amount : (item.quantity != null ? item.quantity : 0));
        if (count <= 0) return;

        const card = document.createElement('div');
        card.className = 'player-item';
        const imageName = item.image && item.image !== '' ? item.image : `${item.name}.png`;
        card.innerHTML = `
            <img src="${getImageSRC(imageName)}" class="item-image" alt="${item.label}" onerror="this.onerror=null;this.src='images/default.png';">
            <div class="item-name">${escHtml(item.label || item.name || 'Desconocido')}</div>
            <div class="item-count">${count}</div>`;
        card.addEventListener('click', () => openMoveModal(item, 'deposit', count));
        grid.appendChild(card);
    });
}

function openMoveModal(item, direction, maxCount) {
    currentTransferItem = item;
    currentTransferDirection = direction;
    currentTransferMax = maxCount;

    const title = direction === 'withdraw' ? 'Sacar del almacén' : 'Agregar al almacén';
    const subtitle = direction === 'withdraw' ?
        `0-${maxCount} disponibles en stash (0=todos)` :
        `0-${maxCount} disponibles en inventario (0=todos)`;

    document.getElementById('stash-qty-title').textContent = title;
    document.getElementById('stash-qty-subtitle').textContent = subtitle;
    const modalInput = document.getElementById('stash-qty-modal-input');
    modalInput.min = 0;
    modalInput.value = 0;

    synchronizeDefaultQty();

    const overlay = document.getElementById('stash-qty-overlay');
    overlay.classList.remove('hidden', 'hiding');
    overlay.querySelector('.modal')?.classList.remove('hiding');
}

function changeStashQty(delta) {
    const input = document.getElementById('stash-qty-modal-input');
    let v = Math.max(1, Math.min(currentTransferMax || 999, (parseInt(input.value) || 1) + delta));
    input.value = v;
}

function confirmStashTransfer() {
    let qty = parseInt(document.getElementById('stash-qty-modal-input').value);
    if (isNaN(qty) || qty < 0) qty = 0;

    if (!currentTransferItem || !currentTransferDirection) return;

    if (qty === 0) {
        qty = currentTransferMax;
    }
    qty = Math.max(1, Math.min(currentTransferMax, qty));

    if (currentTransferDirection === 'withdraw') {
        moveToPlayer(currentTransferItem.name, qty, currentTransferItem.slot);
    } else {
        moveToStash(currentTransferItem.name, qty, currentTransferItem.slot);
    }

    closeStashQtyModal();
}

function applyStashQtyDefault() {
    synchronizeDefaultQty();
}

function synchronizeDefaultQty() {
    const defaultQty = Math.max(1, parseInt(document.getElementById('stash-qty-input').value) || 1);
    document.getElementById('stash-qty-input').value = defaultQty;
    const modalInput = document.getElementById('stash-qty-modal-input');
    if (modalInput) modalInput.value = Math.min(defaultQty, currentTransferMax || defaultQty);
}

function moveToPlayer(itemName, count, fromSlot) {
    nuiPost('moveToPlayer', {
        pointId: currentStashPoint?.id,
        itemName: itemName,
        count: count,
        fromSlot: fromSlot
    });
}

function moveToStash(itemName, count, fromSlot) {
    nuiPost('moveToStash', {
        pointId: currentStashPoint?.id,
        itemName: itemName,
        count: count,
        fromSlot: fromSlot
    });
}

function confirmBuy() {
    if (!currentProduct || !currentShopPoint) return;
    const amount = parseInt(document.getElementById('qty-input').value) || 1;
    nuiPost('buyItem', { pointId: currentShopPoint.id, itemName: currentProduct.item_name, amount });
    closeShop();
}

// ─── ESC handler ─────────────────────────────────────────────
document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;

    // Modales internos primero (no cierran el foco, solo el overlay)
    if (!document.getElementById('qty-overlay').classList.contains('hidden')) {
        closeQtyModal(); return;
    }
    if (!document.getElementById('form-overlay').classList.contains('hidden')) {
        closeFormModal(); return;
    }
    if (!document.getElementById('delete-overlay').classList.contains('hidden')) {
        closeDeleteModal(); return;
    }

    // Cierres que liberan foco
    if (!document.getElementById('shop-overlay').classList.contains('hidden')) {
        closeShop(); return;
    }
    if (!document.getElementById('admin-overlay').classList.contains('hidden')) {
        closeAdmin(); return;
    }
});

// ─── UTIL ────────────────────────────────────────────────────
function escHtml(s) {
    return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;')
        .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
