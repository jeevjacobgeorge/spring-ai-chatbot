package com.example.springAI.controllers;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

import jakarta.servlet.http.HttpSession;

import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller("")
public class WebAppControllerPerplexity {

    private final OpenAiChatModel  chatModel;
    private static final DateTimeFormatter TF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Autowired
    public WebAppControllerPerplexity(OpenAiChatModel  chatModel) {
        this.chatModel = chatModel;
    }

    

    @PostMapping("/perp/chat")
    public String prepChat(@RequestParam("message") String message, HttpSession session, Model model) {
        // call AI (synchronous)
        Prompt prompt = new Prompt(new UserMessage(message));
        ChatResponse aiChatResponse = chatModel.call(prompt);

        // Extract the assistant text from ChatResponse.
        // This line assumes Generation.getOutput().getText() / AssistantMessage.getText() is available.
        // If your Spring AI version differs, adapt to .getMessage().getContent() path accordingly.
        String reply = aiChatResponse.getResults().stream()
                .map(gen -> gen.getOutput())            // AssistantMessage / output
                .filter(Objects::nonNull)
                .map(assistant -> assistant.getText())  // use getText() for assistant content
                .filter(Objects::nonNull)
                .findFirst()
                .orElse("No response from AI");

        // Append to session chat history
        @SuppressWarnings("unchecked")
        List<Map<String, String>> history = (List<Map<String, String>>) session.getAttribute("chatHistory");
        if (history == null) {
            history = new ArrayList<>();
        }

        String now = LocalDateTime.now().format(TF);
        history.add(Map.of("sender", "user", "text", message, "time", now));
        history.add(Map.of("sender", "ai", "text", reply, "time", now));

        session.setAttribute("chatHistory", history);
        model.addAttribute("chatHistory", history);

        return "chat"; // render JSP with history
    }

  
}
