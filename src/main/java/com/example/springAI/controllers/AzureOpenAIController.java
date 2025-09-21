package com.example.springAI.controllers;

import java.util.Map;

import org.springframework.ai.azure.openai.AzureOpenAiChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api/chat")
public class AzureOpenAIController {

    private final AzureOpenAiChatModel chatModel;

    @Autowired
    public AzureOpenAIController(AzureOpenAiChatModel chatModel) {
        this.chatModel = chatModel;
    }

    @PostMapping
    public Map<String, Object> chat(@RequestBody Map<String, String> request) {
        String userMessage = request.get("message");
        if (userMessage == null || userMessage.isEmpty()) {
            return Map.of("error", "Message cannot be empty");
        }

        // Create prompt
        Prompt prompt = new Prompt(userMessage);

        // Call the chat model and directly wrap it in a Map
        return Map.of("generation", this.chatModel.call(prompt));
    }
}
