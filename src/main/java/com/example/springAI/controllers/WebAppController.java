// src/main/java/com/example/springAI/controllers/WebAppController.java
package com.example.springAI.controllers;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

import jakarta.servlet.http.HttpSession;

import org.springframework.ai.azure.openai.AzureOpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class WebAppController {

    private final AzureOpenAiChatModel azureModel;
    private final OpenAiChatModel openAiModel;
    private static final DateTimeFormatter TF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Autowired
    public WebAppController(AzureOpenAiChatModel azureModel, OpenAiChatModel openAiModel) {
        this.azureModel = azureModel;
        this.openAiModel = openAiModel;
    }

    @GetMapping("/")
    public String home(Model model, HttpSession session) {
        Object chatHistoryObj = session.getAttribute("chatHistory");
        List<Map<String, String>> history;
        if (chatHistoryObj instanceof List) {
            history = (List<Map<String, String>>) chatHistoryObj;
        } else {
            history = new ArrayList<>();
            session.setAttribute("chatHistory", history);
        }
        model.addAttribute("chatHistory", history);
        return "chat";
    }

    @PostMapping("/chat")
    public String chat(@RequestParam("message") String message, HttpSession session, Model model) {
        Prompt prompt = new Prompt(new UserMessage(message));

        ChatResponse azureResponse = azureModel.call(prompt);
        ChatResponse openAiResponse = openAiModel.call(prompt);

        String replyAzure = azureResponse.getResults().stream()
                .map(gen -> gen.getOutput())
                .filter(Objects::nonNull)
                .map(assistant -> assistant.getText())
                .filter(Objects::nonNull)
                .findFirst()
                .orElse("No response from Azure model");

        String replyOpenAi = openAiResponse.getResults().stream()
                .map(gen -> gen.getOutput())
                .filter(Objects::nonNull)
                .map(assistant -> assistant.getText())
                .filter(Objects::nonNull)
                .findFirst()
                .orElse("No response from OpenAI model");

        Object chatHistoryObj = session.getAttribute("chatHistory");
        List<Map<String, String>> history;
        if (chatHistoryObj instanceof List) {
            history = (List<Map<String, String>>) chatHistoryObj;
        } else {
            history = new ArrayList<>();
            session.setAttribute("chatHistory", history);
        }

        String now = LocalDateTime.now().format(TF);
        // store a single map per user turn containing both model replies
        Map<String, String> turn = new HashMap<>();
        turn.put("user", message);
        turn.put("azure", replyAzure);
        turn.put("openai", replyOpenAi);
        turn.put("time", now);
        history.add(turn);

        session.setAttribute("chatHistory", history);
        model.addAttribute("chatHistory", history);

        return "redirect:/";
    }

    @PostMapping("/clear")
    public String clear(HttpSession session) {
        session.removeAttribute("chatHistory");
        return "redirect:/";
    }
}
