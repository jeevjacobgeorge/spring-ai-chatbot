<!-- src/main/webapp/WEB-INF/jsp/chat.jsp -->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>AI Chat</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
<div class="app-shell">
    <header class="topbar">
        <div class="brand">AI Comparator</div>
        <div class="actions">
            <form method="post" action="${pageContext.request.contextPath}/clear" style="display:inline;">
                <button class="btn btn-ghost" type="submit">Clear</button>
            </form>
        </div>
    </header>

    <main class="main">
        <section class="chat-area">
            <div class="chat-header">Conversation</div>

            <!-- Prefer request attribute 'chatHistory' (model) then fall back to session scope -->
            <c:choose>
                <c:when test="${not empty chatHistory}">
                    <c:set var="history" value="${chatHistory}" />
                </c:when>
                <c:when test="${not empty sessionScope.chatHistory}">
                    <c:set var="history" value="${sessionScope.chatHistory}" />
                </c:when>
            </c:choose>

            <div id="chatbox" class="chatbox" role="log" aria-live="polite">
                <c:choose>
                    <c:when test="${not empty history}">
                        <c:forEach var="entry" items="${history}">
                            <div class="turn">
                                <div class="turn-top">
                                    <div class="user-line"><c:out value="${entry['user']}" /></div>
                                    <div class="meta"><c:out value="${entry['time']}" /></div>
                                </div>

                                <div class="models">
                                    <div class="model">
                                        <div class="model-label">Azure</div>
                                        <div class="model-content"><c:out value="${entry['azure']}" /></div>
                                    </div>
                                    <div class="model">
                                        <div class="model-label">OpenAI</div>
                                        <div class="model-content"><c:out value="${entry['openai']}" /></div>
                                    </div>
                                </div>
                            </div>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <div class="empty-state"><em>No messages yet — start the conversation!</em></div>
                    </c:otherwise>
                </c:choose>
            </div>
        </section>


    </main>
    <aside class="compose-area">
        <form method="post" action="${pageContext.request.contextPath}/chat" class="compose-form">
            <label for="message" class="sr-only">Message</label>
            <input id="message" name="message" type="text" autocomplete="off" placeholder="Ask both models..." required />
            <div class="compose-actions">
                <button type="submit" class="btn btn-primary">Send</button>
            </div>
        </form>

        <div class="legend">
            <div><span class="dot azure"></span> Azure model</div>
            <div><span class="dot openai"></span> OpenAI model</div>
        </div>
    </aside>
</div>


<!-- html -->
<script>
    // javascript
    (function() {
        function loadScript(src) {
            return new Promise(function(resolve, reject) {
                var s = document.createElement('script');
                s.src = src;
                s.defer = true;
                s.onload = resolve;
                s.onerror = function() { reject(new Error('Failed to load ' + src)); };
                document.head.appendChild(s);
            });
        }

        var libsReady = false;
        function renderMarkdownNode(el, text) {
            if (!el) return;
            var md = text || el.dataset.raw || el.textContent || '';

            if (!libsReady) {
                el.dataset.raw = md;
                el.textContent = md;
                return;
            }

            try {
                var html = DOMPurify.sanitize(marked.parse(md));
                el.innerHTML = html;
                el.dataset.mdRendered = 'true';
                delete el.dataset.raw;
            } catch (e) {
                el.textContent = md;
                console.error('Markdown render failed', e);
            }
        }


        function renderAllUnrendered() {
            document.querySelectorAll('.model-content').forEach(function(el) {
                if (el.dataset.mdRendered !== 'true') {
                    renderMarkdownNode(el, el.dataset.raw || el.textContent || '');
                }
            });
        }

        var chatbox = document.getElementById('chatbox');
        function scrollToBottomIfNear() {
            if (!chatbox) return;

            const threshold = 80; // px from bottom
            const distanceFromBottom =
                chatbox.scrollHeight - chatbox.clientHeight - chatbox.scrollTop;

            if (distanceFromBottom < threshold) {
                chatbox.scrollTop = chatbox.scrollHeight;
            }
        }

        if (!chatbox) return;
        var observer = new MutationObserver(function(muts) {
            muts.forEach(function(m) {
                m.addedNodes.forEach(function(node) {
                    if (!node || node.nodeType !== Node.ELEMENT_NODE) return;
                    if (node.classList && node.classList.contains('model-content')) {
                        renderMarkdownNode(node, node.dataset.raw || node.textContent || '');
                    } else if (node.querySelectorAll) {
                        node.querySelectorAll('.model-content').forEach(function(el) {
                            renderMarkdownNode(el, el.dataset.raw || el.textContent || '');
                        });
                    }
                });
            });
        });
        observer.observe(chatbox, { childList: true, subtree: true });

        Promise.all([
            loadScript('https://cdn.jsdelivr.net/npm/marked@5.1.1/marked.min.js'),
            loadScript('https://cdn.jsdelivr.net/npm/dompurify@2.4.0/dist/purify.min.js')
        ]).then(function() {
            libsReady = true;
            renderAllUnrendered();
        }).catch(function(err) {
            console.warn('Markdown libs failed to load from CDN:', err);
        });

        var form = document.querySelector('form.compose-form') || document.querySelector('form[action$="/chat"]');
        if (!form) return;

        form.addEventListener('submit', function(e) {
            e.preventDefault();
            var fd = new FormData(form);
            var message = (fd.get('message') || '').toString();
            if (!message.trim()) return;

            var turn = document.createElement('div');
            turn.className = 'turn';
            var now = new Date().toLocaleString();
            turn.innerHTML = '<div class="turn-top"><div class="user-line"></div><div class="meta">' + now + '</div></div>' +
                '<div class="models">' +
                '<div class="model"><div class="model-label">Azure</div><div class="model-content" data-target="azure"></div></div>' +
                '<div class="model"><div class="model-label">OpenAI</div><div class="model-content" data-target="openai"></div></div>' +
                '</div>';
            chatbox.appendChild(turn);
            scrollToBottomIfNear();

            var azureNode = turn.querySelector('.model-content[data-target="azure"]');
            var openaiNode = turn.querySelector('.model-content[data-target="openai"]');

            azureNode.classList.add('typing');
            openaiNode.classList.add('typing');

            var streamUrl = (form.action || '').replace(/\/chat$/, '/stream') || (window.location.pathname.replace(/\/$/, '') + '/stream') || '/stream';

            fetch(streamUrl, {
                method: 'POST',
                body: new URLSearchParams({ message: message }),
                headers: { 'Accept': 'text/event-stream', 'Content-Type': 'application/x-www-form-urlencoded' }
            }).then(function(res) {
                if (!res.ok) throw new Error('stream request failed: ' + res.status);
                if (!res.body) throw new Error('streaming not supported by this response');

                var reader = res.body.getReader();
                var decoder = new TextDecoder();
                var buf = '';

                function handleBlock(block) {
                    var lines = block.split('\n');
                    var event = 'message';
                    var data = '';
                    lines.forEach(function(ln) {
                        if (ln.indexOf('event:') === 0) event = ln.slice(6).trim();
                        else if (ln.indexOf('data:') === 0) data += ln.slice(5).trim() + '\n';
                    });
                    data = data.replace(/\n$/, '');
                    if (event === 'typing-start') {
                        // keep showing animation
                    } else if (event === 'azure') {
                        azureNode.classList.remove('typing');
                        // accumulate raw content and render (will be a no-op until libsReady)
                        azureNode.dataset.raw = (azureNode.dataset.raw || '') + data;
                        azureNode.textContent = azureNode.dataset.raw;
                        renderMarkdownNode(azureNode, azureNode.dataset.raw);
                        scrollToBottomIfNear();
                    } else if (event === 'openai') {
                        openaiNode.classList.remove('typing');
                        openaiNode.dataset.raw = (openaiNode.dataset.raw || '') + data;
                        openaiNode.textContent = openaiNode.dataset.raw;
                        renderMarkdownNode(openaiNode, openaiNode.dataset.raw);
                    } else if (event === 'done') {
                        scrollToBottomIfNear();
                    } else if (event === 'error') {
                        azureNode.classList.remove('typing');
                        openaiNode.classList.remove('typing');
                        azureNode.textContent = '[error]';
                    }
                }

                function pushChunk(text) {
                    buf += text;
                    var parts = buf.split('\n\n');
                    for (var i = 0; i < parts.length - 1; i++) {
                        handleBlock(parts[i]);
                    }
                    buf = parts[parts.length - 1];
                }

                function readLoop() {
                    reader.read().then(function(r) {
                        if (r.done) {
                            if (buf.trim()) handleBlock(buf);
                            return;
                        }
                        pushChunk(decoder.decode(r.value, { stream: true }));
                        readLoop();
                    }).catch(function(err) {
                        console.error('Stream read error', err);
                        azureNode.classList.remove('typing');
                        openaiNode.classList.remove('typing');
                    });
                }

                readLoop();
            }).catch(function(err) {
                console.error('Stream setup failed', err);
                azureNode.classList.remove('typing');
                openaiNode.classList.remove('typing');
                azureNode.textContent = 'Failed to stream: ' + (err.message || err);
            });

            form.reset();
        });
    })();

</script>


</body>
</html>
