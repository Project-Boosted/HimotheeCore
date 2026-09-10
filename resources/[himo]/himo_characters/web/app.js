const body = document.body;
const accountId = document.getElementById('accountId');
const characterList = document.getElementById('characterList');
const slotSummary = document.getElementById('slotSummary');
const notice = document.getElementById('notice');
const errorBox = document.getElementById('error');
const createForm = document.getElementById('createForm');
const createButton = document.getElementById('createButton');
const refreshButton = document.getElementById('refreshButton');

let state = {
    characters: [],
    maxCharacters: 4,
    busy: false
};

function resourceName() {
    return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'himo_characters';
}

async function postNui(endpoint, data = {}) {
    const response = await fetch(`https://${resourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });

    return response.json();
}

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function formatDate(value) {
    if (!value) return 'Not set';
    const raw = String(value).slice(0, 10);
    const [year, month, day] = raw.split('-');
    if (!year || !month || !day) return raw;
    return `${day}/${month}/${year}`;
}

function setMessage(element, message) {
    if (!message) {
        element.textContent = '';
        element.classList.add('hidden');
        return;
    }

    element.textContent = message;
    element.classList.remove('hidden');
}

function setBusy(busy) {
    state.busy = busy;
    createButton.disabled = busy || state.characters.length >= state.maxCharacters;
    refreshButton.disabled = busy;
    document.querySelectorAll('.play-button').forEach((button) => {
        button.disabled = busy;
    });
}

function renderCharacters() {
    const used = state.characters.length;
    slotSummary.textContent = `${used} / ${state.maxCharacters} slots used`;
    createButton.disabled = state.busy || used >= state.maxCharacters;

    if (!used) {
        characterList.innerHTML = `
            <div class="empty-state">
                <div>
                    <div class="empty-title">No characters yet</div>
                    <div class="empty-copy">Create your first character using the form on the right.</div>
                </div>
            </div>
        `;
        return;
    }

    characterList.innerHTML = state.characters.map((character) => {
        const fullName = `${escapeHtml(character.first_name)} ${escapeHtml(character.last_name)}`;
        const nationality = escapeHtml(character.nationality || 'Unknown');
        const gender = escapeHtml(character.gender || 'Unspecified');
        const citizen = escapeHtml(character.citizen_id || '—');

        return `
            <article class="character-card">
                <div class="character-slot">Slot ${Number(character.slot) || '?'}</div>
                <div class="character-name">${fullName}</div>
                <div class="character-meta">
                    ${formatDate(character.date_of_birth)}<br>
                    ${nationality} • ${gender}
                </div>
                <div class="card-footer">
                    <span class="citizen-id">${citizen}</span>
                    <button class="play-button" type="button" data-character-id="${Number(character.id)}">Play</button>
                </div>
            </article>
        `;
    }).join('');

    document.querySelectorAll('.play-button').forEach((button) => {
        button.addEventListener('click', async () => {
            if (state.busy) return;
            setBusy(true);
            setMessage(errorBox, null);

            try {
                const result = await postNui('selectCharacter', {
                    characterId: Number(button.dataset.characterId)
                });

                if (!result?.ok) {
                    throw new Error(result?.error || 'Character selection failed.');
                }
            } catch (error) {
                setBusy(false);
                setMessage(errorBox, error.message || 'Character selection failed.');
            }
        });
    });
}

createForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (state.busy || state.characters.length >= state.maxCharacters) return;

    const data = Object.fromEntries(new FormData(createForm).entries());
    setBusy(true);
    setMessage(errorBox, null);
    setMessage(notice, null);

    try {
        const result = await postNui('createCharacter', data);
        if (!result?.ok) {
            throw new Error(result?.error || 'Character creation failed.');
        }
    } catch (error) {
        setBusy(false);
        setMessage(errorBox, error.message || 'Character creation failed.');
    }
});

refreshButton.addEventListener('click', async () => {
    if (state.busy) return;
    setBusy(true);
    setMessage(errorBox, null);

    try {
        const result = await postNui('refreshCharacters');
        if (!result?.ok) {
            throw new Error(result?.error || 'Refresh failed.');
        }
    } catch (error) {
        setBusy(false);
        setMessage(errorBox, error.message || 'Refresh failed.');
    }
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'open') {
        state.characters = Array.isArray(data.characters) ? data.characters : [];
        state.maxCharacters = Number(data.maxCharacters) || 4;
        accountId.textContent = data.accountId ?? '—';
        setMessage(notice, data.notice || null);
        setMessage(errorBox, null);
        setBusy(false);
        renderCharacters();
        body.classList.remove('hidden');
        return;
    }

    if (data.action === 'close') {
        body.classList.add('hidden');
        setBusy(false);
        return;
    }

    if (data.action === 'error') {
        setBusy(false);
        setMessage(errorBox, data.message || 'Something went wrong.');
    }
});
