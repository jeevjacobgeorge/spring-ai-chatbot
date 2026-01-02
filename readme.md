# Spring AI Comparator

Small Java web app that demonstrates using Spring AI to compare responses from Azure OpenAI and OpenAI in one UI. Built with Java, Spring (Spring AI), JavaScript and Maven. Uses server-sent events (SSE) for streaming replies and client-side Markdown rendering (marked + DOMPurify).

## Features
- Compare Azure and OpenAI model outputs side-by-side.
- Streaming endpoint (`/stream`) that emits events: `typing-start`, `azure`, `openai`, `done`, `error`.
- Simple UI at `/` with incremental rendering and safe Markdown sanitization.
- Easy model swapping via Spring bean configuration.

## Requirements
- JDK 17+ (or the JDK targeted by the project)
- Maven
- Internet access for client-side CDN libs (marked, DOMPurify) or include them locally
- Run on Windows (development notes assume IntelliJ IDEA)

## Quickstart

1. Configure credentials (example using environment variables or `application.properties`):
    - Set provider keys and endpoints as required by your Spring AI setup (Azure/OpenAI).
    - Example (in `src/main/resources/application.properties`):
      ```
      # Example placeholders — replace with actual property names used by your Spring AI integration
      AZURE_OPENAI_KEY=your_azure_key
      AZURE_OPENAI_ENDPOINT=https://your-azure-endpoint
      OPENAI_API_KEY=your_openai_key
      ```

2. Build and run:
    - From project root:
      ```
      mvn clean package
      mvn spring-boot:run
      ```
    - Or run the generated jar:
      ```
      java -jar target/your-app.jar
      ```

3. Open browser to `http://localhost:8080/`.

## Endpoints
- `GET /` — UI (JSP at `src/main/webapp/WEB-INF/jsp/chat.jsp`).
- `POST /chat` — synchronous call used by form submit (stores history in session).
- `POST /stream` — SSE streaming endpoint (produces `text/event-stream`) implemented in the controller at `src/main/java/.../WebAppController.java`.

## How it works (high level)
- Server: controller builds a `Prompt` and calls injected model beans (`AzureOpenAiChatModel`, `OpenAiChatModel`). For the stream endpoint, server sends SSE events; final replies are persisted to session history.
- Client: `chat.jsp` uses a small JS module that:
    - Appends a new turn to the DOM when submitting.
    - Calls `/stream` and reads the response body as a stream.
    - Accumulates SSE blocks, updates model panes incrementally.
    - Uses `marked` + `DOMPurify` (loaded from CDN) to render Markdown safely on the client.
    - Auto-scrolls only when the user is already near the bottom to avoid disruptive jumps.

## Troubleshooting
- Responses not rendered as Markdown:
    - Ensure `marked` and `DOMPurify` are loading (network tab). If blocked by CSP, permit the CDN or host the libs locally.
    - Client script sets a `libsReady` flag; if libs load after streamed chunks arrive the code stores raw text in `data-raw` and renders once libs are ready.
- New streamed replies not rendering:
    - The client accumulates chunks into a `data-raw` attribute and calls the render function after each chunk. Verify `renderMarkdownNode` is invoked per chunk.
- Unwanted scrolling:
    - The UI only auto-scrolls when user is near bottom; adjust the threshold in the JS if needed.
- Streaming not supported:
    - Ensure the HTTP response supports streaming (SSE) and client `fetch` reads the body stream. Some proxies or servlet containers may buffer; test locally first.

## Extending / Swapping models
- Models are injected as Spring beans. To swap models or change which model is called, replace the injected bean or change configuration — minimal code changes required.
- If you want parallel calls, modify the `stream` method to call models concurrently (e.g., submit to an `ExecutorService`) and send partial SSE chunks as results arrive.

## Development notes
- Project uses Maven; open in IntelliJ IDEA 2025.3.1 on Windows.
- Session-backed history is rendered on page load; streaming writes are persisted to session once the stream completes.
- Key files:
    - `src/main/java/.../WebAppController.java` (controller + SSE stream)
    - `src/main/webapp/WEB-INF/jsp/chat.jsp` (client UI & JS)
- For local debugging, consider hosting `marked` and `DOMPurify` in `src/main/webapp/static/` to avoid CDN/CSP issues.

## License
MIT — adapt and reuse.
