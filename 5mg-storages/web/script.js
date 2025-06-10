
let managementStashId = null;


function showBackground() {
    const bg = document.getElementById('dynamicBg');
    if (bg) {
        bg.classList.add('active');
    }
}

function hideBackground() {
    const bg = document.getElementById('dynamicBg');
    if (bg) {
        bg.classList.remove('active');
    }
}


window.addEventListener('message', function(event) {
    const data = event.data;
    

    switch (data.action) {
        case 'showUI':
            document.body.style.display = 'block';
            showBackground();
            break;
            
        case 'forceCloseUI':
            closeUI();
            break;
            
        case 'openPurchaseUI':
            showBackground();
            showPurchaseUI(data.data);
            break;
            
        case 'openManagementUI':
            showBackground();
            showManagementUI(data.data);
            break;
            
        case 'showStorageManagement':
            showStorageDetail(data.data);
            break;
            
        case 'shareAccessResponse':

            if (data.data && data.data.success) {
                showNotification('Success', 'Player successfully added to the shared access list.', 'success');
                

                fetch(`https://5mg-storages/getSharedAccess`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        stashId: managementStashId
                    })
                });
            } else {
                const errorMsg = data.data && data.data.message ? data.data.message : 'Failed to add access. Player not found.';
                showNotification('Error', errorMsg, 'error');
            }
            break;
            
        case 'showError':
            showErrorNotification(data.message);
            break;
    }
});


document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});


function showErrorNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'notification error';
    notification.innerHTML = `
        <i class="fas fa-exclamation-circle"></i>
        <span>${message}</span>
    `;
    
    document.body.appendChild(notification);
    

    setTimeout(() => {
        notification.classList.add('fade-out');
        setTimeout(() => {
            notification.remove();
        }, 500);
    }, 3000);
}


function showNotification(title, message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div class="notification-header">
            <strong>${title}</strong>
            <button class="close-notification">&times;</button>
        </div>
        <div class="notification-body">
            ${message}
        </div>
    `;
    
    document.body.appendChild(notification);
    

    notification.querySelector('.close-notification').addEventListener('click', function() {
        notification.classList.add('fade-out');
        setTimeout(() => {
            notification.remove();
        }, 300);
    });
    

    setTimeout(() => {
        notification.classList.add('fade-out');
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 5000);
    

    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
}


document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.close-modal').forEach(button => {
        button.addEventListener('click', function() {
            closeModal(this.closest('.modal'));
        });
    });
    

    document.getElementById('purchase-btn').addEventListener('click', purchaseStorage);
    document.getElementById('cancel-purchase-btn').addEventListener('click', closeUI);
    

    document.getElementById('buy-new-storage-btn').addEventListener('click', function() {
        fetch(`https://5mg-storages/closeUI`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        }).then(() => {
            setTimeout(() => {
                fetch(`https://5mg-storages/showPurchaseUI`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({})
                });
            }, 200);
        });
    });
    

    document.querySelectorAll('.icon-option').forEach(option => {
        option.addEventListener('click', function() {
            document.querySelectorAll('.icon-option').forEach(opt => opt.classList.remove('selected'));
            this.classList.add('selected');
        });
    });
    

    document.getElementById('open-storage-btn').addEventListener('click', openStorage);
    document.getElementById('rename-storage-btn').addEventListener('click', () => showModal('rename-modal'));
    document.getElementById('upgrade-storage-btn').addEventListener('click', upgradeStorage);
    

    document.getElementById('confirm-rename-btn').addEventListener('click', renameStorage);
    document.getElementById('confirm-icon-btn').addEventListener('click', changeIcon);
});


function showPurchaseUI(data) {
    document.getElementById('storage-price').textContent = `$${data.price}`;
    document.getElementById('storage-capacity').textContent = `${data.capacity} slots`;
    
    hideAllContainers();
    document.getElementById('purchase-container').classList.add('active');
}

function showManagementUI(data) {
    hideAllContainers();
    document.getElementById('management-container').classList.add('active');
    

    const storageList = document.getElementById('storage-list');
    storageList.innerHTML = '';
    

    if (data.storageUnits && data.storageUnits.length > 0) {
        data.storageUnits.forEach(unit => {
            const storageCard = createStorageCard(unit);
            storageList.appendChild(storageCard);
        });
    } else {

        const noStorage = document.createElement('div');
        noStorage.className = 'no-storage-message';
        noStorage.innerHTML = '<i class="fas fa-exclamation-circle"></i><p>You don\'t have any storage units yet.</p>';
        storageList.appendChild(noStorage);
    }
}


function createStorageCard(unit) {
    const card = document.createElement('div');
    card.className = 'storage-card';
    card.dataset.stashId = unit.stashId;
    

    const header = document.createElement('div');
    header.className = 'storage-card-header';
    header.innerHTML = `
        <i class="fas fa-${unit.icon || 'box'}"></i>
        <h3>${unit.label || 'Storage Unit'}</h3>
    `;
    

    const body = document.createElement('div');
    body.className = 'storage-card-body';
    body.innerHTML = `
        <div class="storage-info">
            <div class="storage-info-row">
                <span>Level:</span>
                <span>${unit.level || 1}</span>
            </div>
            <div class="storage-info-row">
                <span>Weight:</span>
                <span>${unit.weight || 0} kg</span>
            </div>
        </div>
        <div class="storage-card-buttons">
            <button class="btn btn-secondary manage-btn">
                <i class="fas fa-cog"></i> Manage
            </button>
            <button class="btn btn-primary open-btn">
                <i class="fas fa-box-open"></i> Open
            </button>
        </div>
    `;
    

    card.appendChild(header);
    card.appendChild(body);
    

    const manageBtn = body.querySelector('.manage-btn');
    const openBtn = body.querySelector('.open-btn');
    
    manageBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        fetch(`https://5mg-storages/openStorageManagement`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                stashId: unit.stashId
            })
        });
    });
    
    openBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        console.log('Opening storage with ID:', unit.stashId);
        if (!unit.stashId) {
            console.error('Error: Storage ID is undefined');
            showErrorNotification('Storage ID is missing. Please try refreshing the page.');
            return;
        }
        fetch(`https://5mg-storages/openStorage`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                stashId: unit.stashId
            })
        });
    });
    
    return card;
}


function showStorageDetail(data) {
    managementStashId = data.stashId;
    
    document.getElementById('modal-storage-name').textContent = data.label;
    document.getElementById('modal-storage-icon').className = `fas fa-${data.icon || 'box'}`;
    document.getElementById('storage-level').textContent = data.level;
    document.getElementById('storage-weight').textContent = data.weight || 0;
    

    const upgradeBtn = document.getElementById('upgrade-storage-btn');
    upgradeBtn.style.display = 'flex';
    

    showModal('storage-detail-modal');
}


function purchaseStorage() {
    const storageName = document.getElementById('storage-name').value.trim();
    
    if (!storageName) {
        showNotification('Error', 'Please enter a storage name', 'error');
        return;
    }
    

    const selectedIcon = document.querySelector('.icon-option.selected');
    const icon = selectedIcon ? selectedIcon.dataset.icon : 'box';
    

    fetch(`https://5mg-storages/purchaseStorage`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            label: storageName,
            icon: icon
        })
    });
    

    setTimeout(() => {
        closeUI();
    }, 200);
}


function openStorage() {
    fetch(`https://5mg-storages/openStorage`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            stashId: managementStashId
        })
    });
}


function showRenameModal() {
    document.getElementById('new-storage-name').value = document.getElementById('modal-storage-name').textContent;
    showModal('rename-modal');
    document.getElementById('new-storage-name').focus();
}


function renameStorage() {
    const newName = document.getElementById('new-storage-name').value.trim();
    
    if (!newName) {
        showNotification('Error', 'Please enter a storage name', 'error');
        return;
    }
    

    fetch(`https://5mg-storages/renameStorage`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            stashId: managementStashId,
            newLabel: newName
        })
    });
    

    document.getElementById('modal-storage-name').textContent = newName;
    

    closeModal(document.getElementById('rename-modal'));
}


function showIconModal() {
    showModal('icon-modal');
}


function changeIcon() {
    const selectedIcon = document.querySelector('#icon-modal .icon-option.selected');
    if (!selectedIcon) return;
    
    const icon = selectedIcon.dataset.icon;
    
    fetch(`https://5mg-storages/changeIcon`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            stashId: managementStashId,
            icon: icon
        })
    });

    document.getElementById('modal-storage-icon').className = `fas fa-${icon}`;
    

    closeModal(document.getElementById('icon-modal'));
}

function upgradeStorage() {
    fetch(`https://5mg-storages/upgradeStorage`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            stashId: managementStashId
        })
    });
}


function showAddAccessModal() {
    showModal('add-access-modal');
    document.getElementById('player-id').value = '';
    document.getElementById('player-id').focus();
}


function addAccess() {
    const playerId = parseInt(document.getElementById('player-id').value.trim());
    if (isNaN(playerId) || playerId <= 0) {
        showNotification('Error', 'Enter a valid player ID', 'error');
        return;
    }
    
    console.log(`Adding access for player ID: ${playerId} to storage: ${managementStashId}`);
    

    closeModal(document.getElementById('add-access-modal'));
    

    showNotification('Processing', 'Checking player information...', 'info');
    
    fetch(`https://5mg-storages/shareAccess`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            stashId: managementStashId,
            playerId: playerId
        })
    });
    

}


function removeAccess(identifier) {
    fetch(`https://5mg-storages/removeAccess`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            stashId: managementStashId,
            identifier: identifier
        })
    }).then(() => {
        showNotification('Success', 'Player successfully removed from the shared access list.', 'success');
    });
}


function showModal(modalId) {

    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.remove('active');
    });
    

    document.getElementById(modalId).classList.add('active');
    

    document.getElementById(modalId).addEventListener('click', function(event) {
        if (event.target === this) {
            closeModal(this);
        }
    });
    

    if (modalId === 'icon-modal') {
        document.querySelectorAll('#icon-modal .icon-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('#icon-modal .icon-option').forEach(opt => opt.classList.remove('selected'));
                this.classList.add('selected');
            });
        });
    }
}


function closeModal(modal) {
    modal.classList.remove('active');
}


function hideAllContainers() {
    document.querySelectorAll('.container').forEach(container => {
        container.classList.remove('active');
    });
}


function closeUI() {

    hideAllContainers();
    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.remove('active');
    });
    

    hideBackground();
    

    managementStashId = null;
    

    fetch(`https://5mg-storages/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}