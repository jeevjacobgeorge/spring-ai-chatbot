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

<script>
    // auto-scroll to bottom of chatbox on page load
    (function() {
        var box = document.getElementById('chatbox');
        if (box) {
            box.scrollTop = box.scrollHeight;
        }
    })();
</script>
<!-- add to the bottom of `src/main/webapp/WEB-INF/jsp/chat.jsp` (before </body>) -->
<script src="marked.min.js"></script>
<script src="purify.min.js"></script>
<!-- html -->
<script>
    (function() {
        // async script loader
        function loadScript(src) {
            return new Promise(function(resolve, reject) {
                var s = document.createElement('script');
                s.src = src;
                s.defer = true;
                s.onload = function() { resolve(); };
                s.onerror = function() { reject(new Error('Failed to load ' + src)); };
                document.head.appendChild(s);
            });
        }

        // render a single .model-content element if not already rendered
        function renderNode(el, observer) {
            if (!el || el.dataset.mdRendered === 'true') return;
            var md = el.textContent || '';
            if (!md.trim()) {
                el.dataset.mdRendered = 'true';
                return;
            }
            try {
                if (observer) observer.disconnect(); // avoid observer reentrancy
                var html = DOMPurify.sanitize(marked.parse(md));
                el.innerHTML = html;
                el.dataset.mdRendered = 'true';
            } catch (e) {
                console.error('Markdown render error', e);
            } finally {
                if (observer) observer.observe(chatbox, { childList: true, subtree: true });
            }
        }

        // render all existing nodes once libs are ready
        function renderAll(observer) {
            document.querySelectorAll('.model-content').forEach(function(el) {
                renderNode(el, observer);
            });
        }

        // wait for DOM ready, load libs, then set up observer + initial render
        function init() {
            var chatbox = document.getElementById('chatbox');
            if (!chatbox) return;

            // MutationObserver processes only added nodes to minimize work
            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(m) {
                    m.addedNodes.forEach(function(node) {
                        if (!node) return;
                        if (node.nodeType !== Node.ELEMENT_NODE) return;
                        // if a whole turn was added, render any .model-content inside it
                        if (node.classList && node.classList.contains('model-content')) {
                            renderNode(node, observer);
                        } else {
                            node.querySelectorAll && node.querySelectorAll('.model-content').forEach(function(el) {
                                renderNode(el, observer);
                            });
                        }
                    });
                });
            });

            // start observing and render what's already present
            observer.observe(chatbox, { childList: true, subtree: true });
            renderAll(observer);
        }

        // load libraries non-blocking and initialize
        Promise.all([
            loadScript('https://cdn.jsdelivr.net/npm/marked/marked.min.js'),
            loadScript('https://cdn.jsdelivr.net/npm/dompurify@2.4.0/dist/purify.min.js')
        ])
            .then(function() {
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', init);
                } else {
                    init();
                }
            })
            .catch(function(err) {
                console.error('Failed to load Markdown libraries:', err);
                // still attempt a best-effort render pass without libs (no-op)
            });
    })();
</script>


</body>
</html>
