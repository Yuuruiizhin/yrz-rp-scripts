// ============================================================
//  ox_stash_store | ADMIN.JS  (v2 - fixed)
// ============================================================

'use strict';

let allPoints       = [];
let playerCoords    = { x: 0, y: 0, z: 0 };
let editingId       = null;
let deletingId      = null;
let productRowCount = 0;

// ─── ABRIR / CERRAR ──────────────────────────────────────────
function openAdmin(points, coords) {
    allPoints    = points    || [];
    playerCoords = coords    || { x: 0, y: 0, z: 0 };
    renderAllTabs();
    document.getElementById('admin-overlay').classList.remove('hidden');
    switchTab('points');
}

function closeAdmin() {
    // Cerrar todo primero con animación
    animateCloseOverlay('form-overlay');
    animateCloseOverlay('delete-overlay');
    animateCloseOverlay('admin-overlay');
    editingId  = null;
    deletingId = null;
    // Liberar foco del mouse — único lugar donde se llama closeUI
    nuiPost('closeUI');
}

// ─── TABS ────────────────────────────────────────────────────
function switchTab(tab) {
    document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
    document.getElementById(`tab-${tab}`)?.classList.add('active');
    document.querySelector(`[data-tab="${tab}"]`)?.classList.add('active');
}

// ─── RENDER ──────────────────────────────────────────────────
function renderAllTabs() {
    renderPointsTable(allPoints);
    renderCardsGrid('stashes-grid', allPoints.filter(p => p.category === 'stash'));
    renderCardsGrid('shops-grid',   allPoints.filter(p => p.category === 'shop'));
}

function filterPoints() {
    const q = (document.getElementById('search-input').value || '').toLowerCase();
    renderPointsTable(allPoints.filter(p =>
        p.name.toLowerCase().includes(q) ||
        String(p.id).includes(q) ||
        (p.job || '').toLowerCase().includes(q)
    ));
}

function renderPointsTable(points) {
    const tbody = document.getElementById('points-tbody');
    tbody.innerHTML = '';
    if (!points.length) {
        tbody.innerHTML = `<tr><td colspan="7"><div class="empty-state">
            <span class="empty-icon">📭</span><span>Sin puntos registrados</span></div></td></tr>`;
        return;
    }
    points.forEach(p => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><span class="coords-mono">#${p.id}</span></td>
            <td><strong>${escHtml(p.name)}</strong></td>
            <td>${p.category==='stash'
                ? '<span class="badge badge-stash">📦 Stash</span>'
                : '<span class="badge badge-shop">🛒 Tienda</span>'}</td>
            <td>${(p.job && p.job!=='') ? escHtml(p.job) : '<em style="color:var(--text-muted)">Público</em>'}</td>
            <td><span class="coords-mono">${fc(p.coords_x)}, ${fc(p.coords_y)}, ${fc(p.coords_z)}</span></td>
            <td>${p.creator_name ? escHtml(p.creator_name) : '<em style="color:var(--text-muted)">—</em>'}</td>
            <td><div class="action-btns">
                <button class="btn btn-edit"      onclick="openEditModal(${p.id})">✏️ Editar</button>
                <button class="btn btn-duplicate" onclick="duplicatePoint(${p.id})">📄 Duplicar</button>
                <button class="btn btn-delete"    onclick="openDeleteModal(${p.id},'${escHtml(p.name)}')">🗑️</button>
            </div></td>`;
        tbody.appendChild(tr);
    });
}

function renderCardsGrid(containerId, points) {
    const c = document.getElementById(containerId);
    c.innerHTML = '';
    if (!points.length) {
        c.innerHTML = `<div class="empty-state" style="grid-column:1/-1">
            <span class="empty-icon">📭</span><span>Sin registros</span></div>`;
        return;
    }
    points.forEach(p => {
        const card = document.createElement('div');
        card.className = 'point-card';
        card.innerHTML = `
            <div class="point-card-header">
                <div><div class="point-card-name">${escHtml(p.name)}</div>
                <div class="point-card-id">#${p.id}</div></div>
            </div>
            <div class="point-card-meta">
                <span>💼 ${(p.job && p.job!=='') ? escHtml(p.job) : 'Público'}</span>
                ${p.category==='stash'
                    ? `<span>⚖️ ${(p.max_weight||100000).toLocaleString()} g | 🗂️ ${p.max_slots||50} slots</span>`
                    : `<span>📦 ${(p.products||[]).length} producto(s)</span>`}
                <span class="coords-mono" style="font-size:.68rem;color:var(--text-muted)">
                    ${fc(p.coords_x)}, ${fc(p.coords_y)}, ${fc(p.coords_z)}</span>
            </div>
            <div class="point-card-actions">
                <button class="btn btn-edit" style="flex:1" onclick="openEditModal(${p.id})">✏️ Editar</button>
                <button class="btn btn-duplicate" onclick="duplicatePoint(${p.id})">📄 Duplicar</button>
                <button class="btn btn-delete" onclick="openDeleteModal(${p.id},'${escHtml(p.name)}')">🗑️</button>
            </div>`;
        c.appendChild(card);
    });
}

// ─── MODAL CREAR / EDITAR ────────────────────────────────────
function openCreateModal(cat = null) {
    editingId = null; productRowCount = 0;
    document.getElementById('form-title').textContent  = '✨ Nuevo Punto';
    document.getElementById('form-id').value           = '';
    document.getElementById('form-name').value         = '';
    document.getElementById('form-job').value          = '';
    document.getElementById('form-x').value            = fc(playerCoords.x);
    document.getElementById('form-y').value            = fc(playerCoords.y);
    document.getElementById('form-z').value            = fc(playerCoords.z);
    document.getElementById('form-weight').value       = 100000;
    document.getElementById('form-slots').value        = 50;
    document.getElementById('form-category').value     = cat || 'stash';
    resetProductsList();
    onCategoryChange();
    document.getElementById('form-overlay').classList.remove('hidden');
    document.getElementById('form-name').focus();
}

function openEditModal(id) {
    const p = allPoints.find(x => x.id === id);
    if (!p) return;
    editingId = id; productRowCount = 0;

    document.getElementById('form-title').textContent  = `✏️ Editar #${id}`;
    document.getElementById('form-id').value           = id;
    document.getElementById('form-name').value         = p.name;
    document.getElementById('form-job').value          = p.job || '';
    document.getElementById('form-x').value            = fc(p.coords_x);
    document.getElementById('form-y').value            = fc(p.coords_y);
    document.getElementById('form-z').value            = fc(p.coords_z);
    document.getElementById('form-weight').value       = p.max_weight || 100000;
    document.getElementById('form-slots').value        = p.max_slots  || 50;
    document.getElementById('form-category').value     = p.category;

    resetProductsList();
    if (p.category === 'shop' && p.products) {
        p.products.forEach(pr => addProductRow(pr.item_name, pr.label, pr.price));
    }
    onCategoryChange();
    document.getElementById('form-overlay').classList.remove('hidden');
    document.getElementById('form-name').focus();
}

function closeFormModal() {
    animateCloseOverlay('form-overlay');
    editingId = null;
    // NO liberar foco — admin panel sigue abierto
}

function duplicatePoint(id) {
    const p = allPoints.find(x => x.id === id);
    if (!p) {
        showToast('Punto no encontrado para duplicar.', 'error');
        return;
    }

    const newPoint = {
        name: `${p.name} (copia)`,
        category: p.category,
        job: p.job || '',
        coords: { x: parseFloat(p.coords_x), y: parseFloat(p.coords_y), z: parseFloat(p.coords_z) },
        max_weight: p.max_weight || 100000,
        max_slots: p.max_slots || 50,
        products: Array.isArray(p.products) ? p.products.map(product => ({ ...product })) : [],
    };

    nuiPost('admin:createPoint', newPoint);
    showToast('Duplicando punto...');
}


function useCurrentCoords() {
    document.getElementById('form-x').value = fc(playerCoords.x);
    document.getElementById('form-y').value = fc(playerCoords.y);
    document.getElementById('form-z').value = fc(playerCoords.z);
}

function onCategoryChange() {
    const isShop = document.getElementById('form-category').value === 'shop';
    document.querySelectorAll('.stash-only').forEach(el => {
        el.style.display = isShop ? 'none' : '';
    });
    const ps = document.getElementById('products-section');
    if (isShop) ps.classList.remove('hidden');
    else        ps.classList.add('hidden');
}

// ─── PRODUCTOS ───────────────────────────────────────────────
function resetProductsList() {
    document.getElementById('products-list').innerHTML = `
        <div class="products-col-header">
            <span>Item Name (OX)</span><span>Etiqueta</span><span>Precio $</span><span></span>
        </div>`;
}

function addProductRow(item = '', label = '', price = 1) {
    productRowCount++;
    const idx = productRowCount;
    const row = document.createElement('div');
    row.className = 'product-row';
    row.id = `prod-row-${idx}`;
    row.innerHTML = `
        <input type="text"   class="prod-item"  placeholder="water"  value="${escHtml(item)}">
        <input type="text"   class="prod-label" placeholder="Agua"   value="${escHtml(label)}">
        <input type="number" class="prod-price" placeholder="10"     value="${price}" min="0">
        <button class="del-row" onclick="document.getElementById('prod-row-${idx}').remove()">✕</button>`;
    document.getElementById('products-list').appendChild(row);
}

function collectProducts() {
    return [...document.querySelectorAll('#products-list .product-row')].map(row => ({
        item_name: row.querySelector('.prod-item')?.value.trim()  || '',
        label:     row.querySelector('.prod-label')?.value.trim() || '',
        price:     parseInt(row.querySelector('.prod-price')?.value) || 0,
    })).filter(p => p.item_name);
}

// ─── GUARDAR (sin await en NUI) ──────────────────────────────
function savePoint() {
    const name   = document.getElementById('form-name').value.trim();
    const cat    = document.getElementById('form-category').value;
    const job    = document.getElementById('form-job').value.trim();
    const x      = parseFloat(document.getElementById('form-x').value);
    const y      = parseFloat(document.getElementById('form-y').value);
    const z      = parseFloat(document.getElementById('form-z').value);
    const weight = parseInt(document.getElementById('form-weight').value) || 100000;
    const slots  = parseInt(document.getElementById('form-slots').value)  || 50;

    if (!name)                       { showToast('Nombre obligatorio.', 'error'); return; }
    if (isNaN(x)||isNaN(y)||isNaN(z)){ showToast('Coordenadas inválidas.', 'error'); return; }

    const data = {
        name, category: cat, job,
        coords: { x, y, z },
        max_weight: weight, max_slots: slots,
        products: cat === 'shop' ? collectProducts() : [],
    };

    if (editingId) {
        data.id = editingId;
        nuiPost('admin:editPoint', data);
    } else {
        nuiPost('admin:createPoint', data);
    }

    closeFormModal();
    showToast('Guardando cambios...', 'info');
    // El servidor llama RefreshPointsCache() → adminPointsUpdated → NUI se actualiza sola
}

// ─── DELETE ──────────────────────────────────────────────────
function openDeleteModal(id, name) {
    deletingId = id;
    document.getElementById('delete-msg').textContent =
        `¿Eliminar "${name}" (ID: ${id})? Esta acción no se puede deshacer.`;
    document.getElementById('delete-overlay').classList.remove('hidden');
}

function closeDeleteModal() {
    animateCloseOverlay('delete-overlay');
    deletingId = null;
}

function confirmDelete() {
    if (!deletingId) return;
    nuiPost('admin:deletePoint', { id: deletingId });
    closeDeleteModal();
    showToast('Eliminando punto...', 'info');
}

// ─── UTILS ───────────────────────────────────────────────────
function fc(n) { return parseFloat(n || 0).toFixed(4); }

function escHtml(s) {
    return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;')
        .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
