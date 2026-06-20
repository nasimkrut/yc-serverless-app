document.getElementById('front-version').textContent = FRONT_VERSION;

async function loadVersion() {
    try {
        const res = await fetch(API_URL + '/api/version');
        const data = await res.json();
        document.getElementById('back-version').textContent = data.version;
        document.getElementById('instance-id').textContent = data.instance;
    } catch {
        document.getElementById('back-version').textContent = 'unavailable';
        document.getElementById('instance-id').textContent = '—';
    }
}

async function loadMessages() {
    const container = document.getElementById('messages');
    try {
        const res = await fetch(API_URL + '/api/messages');
        const messages = await res.json();
        if (messages.length === 0) {
            container.innerHTML = '<p class="empty">No messages yet. Be the first!</p>';
        } else {
            container.innerHTML = messages.map(m =>
                `<div class="message">
                    <p>${escapeHtml(m.text)}</p>
                    <time>${new Date(m.createdAt).toLocaleString()}</time>
                </div>`
            ).join('');
        }
    } catch {
        container.innerHTML = '<p class="error">Failed to load messages.</p>';
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
}

async function sendMessage() {
    const textarea = document.getElementById('message-text');
    const text = textarea.value.trim();
    const errorDiv = document.getElementById('send-error');
    const button = document.getElementById('send-btn');

    errorDiv.textContent = '';
    if (!text) return;

    button.disabled = true;
    button.textContent = 'Sending...';

    try {
        const res = await fetch(API_URL + '/api/messages', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text })
        });
        if (!res.ok) throw new Error('Server error');
        textarea.value = '';
        await loadMessages();
        await loadVersion();
    } catch {
        errorDiv.textContent = 'Failed to send. Please try again.';
    } finally {
        button.disabled = false;
        button.textContent = 'Send';
    }
}

loadVersion();
loadMessages();
