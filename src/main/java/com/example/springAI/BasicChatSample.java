package com.example.springAI;

import java.util.Arrays;
import java.util.List;

import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.ChatChoice;
import com.azure.ai.openai.models.ChatCompletions;
import com.azure.ai.openai.models.ChatCompletionsOptions;
import com.azure.ai.openai.models.ChatRequestMessage;
import com.azure.ai.openai.models.ChatRequestSystemMessage;
import com.azure.ai.openai.models.ChatRequestUserMessage;
import com.azure.ai.openai.models.ChatResponseMessage;
import com.azure.core.credential.AzureKeyCredential;

public final class BasicChatSample {
    public static void main(String[] args) {
        // 🔹 Paste your Azure OpenAI details here
        String apiKey = ""; 
        String endpoint = "https://jeevj-mftifukg-eastus2.cognitiveservices.azure.com/";
        String deploymentName = "gpt-4.1";

        // 🔹 Initialize OpenAI Client
        OpenAIClient client = new OpenAIClientBuilder()
            .credential(new AzureKeyCredential(apiKey))
            .endpoint(endpoint)
            .buildClient();

        // 🔹 Create chat messages
        List<ChatRequestMessage> chatMessages = Arrays.asList(
            new ChatRequestSystemMessage("You are a helpful assistant."),
            new ChatRequestUserMessage("I am going to Paris, what should I see?")
        );

        ChatCompletionsOptions chatCompletionsOptions = new ChatCompletionsOptions(chatMessages);
        chatCompletionsOptions.setMaxTokens(500);  // Reasonable token limit
        chatCompletionsOptions.setTemperature(0.7); // Creativity level

        // 🔹 Get response from Azure OpenAI
        ChatCompletions chatCompletions = client.getChatCompletions(deploymentName, chatCompletionsOptions);

        // 🔹 Print response
        System.out.printf("Model ID=%s | Created at %s%n", 
                          chatCompletions.getId(), chatCompletions.getCreatedAt());

        for (ChatChoice choice : chatCompletions.getChoices()) {
            ChatResponseMessage message = choice.getMessage();
            System.out.printf("Index: %d, Role: %s%n", choice.getIndex(), message.getRole());
            System.out.println("Message:");
            System.out.println(message.getContent());
        }
    }
}
