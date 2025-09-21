package com.example.springAI.controllers;

import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.azure.openai.AzureOpenAiChatModel;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/stream-chat")
public class StreamingChatController {

    private final AzureOpenAiChatModel chatModel;

    public StreamingChatController(AzureOpenAiChatModel chatModel) {
        this.chatModel = chatModel;
    }

    // Streaming endpoint (Server-Sent Events)
    @GetMapping(produces = "text/event-stream")
    public Flux<ChatResponse> generateStream(@RequestParam String message) {
        Prompt prompt = new Prompt(new UserMessage(message));
        return this.chatModel.stream(prompt);
    }
}
