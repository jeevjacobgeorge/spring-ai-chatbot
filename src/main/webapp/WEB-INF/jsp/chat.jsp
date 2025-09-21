<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>AI Chat</title>
    <style>
        body { font-family: Arial, sans-serif; background:#fafafa; padding:20px; }
        .container { max-width:700px; margin:0 auto; }
        h1 { text-align:center; }

        #chatbox {
            width: 100%;
            min-height: 360px;
            border-radius: 8px;
            border: 1px solid #ddd;
            padding: 16px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
            overflow-y: auto;
            background: #fff;
            display:flex;
            flex-direction:column;
            gap:8px;
        }

        .bubble {
            max-width: 80%;
            padding: 10px 12px;
            border-radius: 12px;
            line-height:1.4;
            display:inline-block;
            word-wrap:break-word;
        }
        .from-user {
            align-self: flex-end;
            background: #d0e6ff;
            color: #003a6b;
            border-bottom-right-radius: 2px;
        }
        .from-ai {
            align-self: flex-start;
            background: #e9f5ea;
            color: #043a0b;
            border-bottom-left-radius: 2px;
        }

        .meta {
            font-size: 0.8rem;
            color: #666;
            margin-top:4px;
        }

        form { margin-top: 12px; display:flex; gap:8px; }
        input[type="text"] { flex:1; padding:10px; border-radius:6px; border:1px solid #ccc; }
        button { padding:10px 14px; border-radius:6px; border:none; background:#1976d2; color:white; cursor:pointer; }
        button.secondary { background:#e0e0e0; color:#333; }
    </style>
</head>
<body>
<div class="container">
    <h1>AI Chat</h1>

    <div id="chatbox" role="log" aria-live="polite">
        <c:choose>
            <c:when test="${not empty sessionScope.chatHistory}">
                <c:forEach var="entry" items="${sessionScope.chatHistory}">
                    <c:choose>
                        <c:when test="${entry['sender'] == 'user'}">
                            <div>
                                <div class="bubble from-user"><c:out value="${entry['text']}" /></div>
                                <div class="meta" style="text-align:right;"><c:out value="${entry['time']}" /></div>
                            </div>
                        </c:when>
                        <c:otherwise>
                            <div>
                                <div class="bubble from-ai"><c:out value="${entry['text']}" /></div>
                                <div class="meta" style="text-align:left;"><c:out value="${entry['time']}" /></div>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </c:forEach>
            </c:when>
            <c:otherwise>
                <div style="color:#666;"><em>No messages yet — start the conversation!</em></div>
            </c:otherwise>
        </c:choose>
    </div>

    <form method="post" action="${pageContext.request.contextPath}/chat">
        <input type="text" name="message" placeholder="Type your message..." required autocomplete="off" />
        <button type="submit">Send</button>
        <button type="submit" formaction="${pageContext.request.contextPath}/clear" formmethod="post" class="secondary">Clear</button>
    </form>
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
</body>
</html>
