import gradio as gr
import requests

OLLAMA_MODEL = "gemma3:1b"  # or mistral, gemma, etc.
OLLAMA_URL = "http://localhost:11434/api/chat"

def chat_with_ollama(history, message):
    response = requests.post(
        OLLAMA_URL,
        json={
            "model": OLLAMA_MODEL,
            "messages": [{"role": "user", "content": message}],
            "stream": False
        },
        timeout=60
    )

    if response.status_code == 200:
        data = response.json()
        reply = data.get("message", {}).get("content", "No response.")
        history.append((message, reply))
        return history, ""
    else:
        return history, f"Error: {response.text}"

with gr.Blocks(title="Ollama Chatbot") as demo:
    gr.Markdown("## 🤖 Chat with Ollama-powered Bot")
    chatbot = gr.Chatbot()
    msg = gr.Textbox(placeholder="Type your message here...", label="Your Message")
    send_btn = gr.Button("Send")

    def respond(message, history):
        return chat_with_ollama(history, message)

    send_btn.click(fn=respond, inputs=[msg, chatbot], outputs=[chatbot, msg])
    msg.submit(fn=respond, inputs=[msg, chatbot], outputs=[chatbot, msg])

if __name__ == "__main__":
    demo.launch(server_name="localhost", server_port=8089)