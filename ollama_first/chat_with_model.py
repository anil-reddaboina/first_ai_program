import gradio as gr
import requests
import json
from typing import List, Tuple, Dict, Any

OLLAMA_MODEL = "gemma3:1b"  # or mistral, gemma, etc.
OLLAMA_URL = "http://localhost:11434/api/chat"

def validate_message(message: str) -> str:
    """Validate and clean the input message."""
    if not message or not message.strip():
        return "Please enter a message."
    return message.strip()

def chat_with_ollama(history: List[Dict[str, str]], message: str) -> Tuple[List[Dict[str, str]], str]:
    """Chat with Ollama model with improved error handling."""
    try:
        # Validate input
        message = validate_message(message)
        if message == "Please enter a message.":
            return history, message

        # Prepare the request
        payload = {
            "model": OLLAMA_MODEL,
            "messages": [{"role": "user", "content": message}],
            "stream": False
        }

        # Make the request with timeout
        response = requests.post(
            OLLAMA_URL,
            json=payload,
            timeout=60,
            headers={"Content-Type": "application/json"}
        )

        # Handle the response
        if response.status_code == 200:
            try:
                data = response.json()
                reply = data.get("message", {}).get("content", "No response from model.")
                history.append({"role": "user", "content": message})
                history.append({"role": "assistant", "content": reply})
                return history, ""
            except json.JSONDecodeError:
                return history, "Error: Invalid response from model."
        else:
            error_msg = f"Error {response.status_code}: {response.text}"
            return history, error_msg

    except requests.exceptions.Timeout:
        return history, "Error: Request timed out. Please try again."
    except requests.exceptions.ConnectionError:
        return history, "Error: Could not connect to Ollama. Please make sure it's running."
    except Exception as e:
        return history, f"Error: An unexpected error occurred: {str(e)}"

with gr.Blocks(title="Anil AI Studio", theme=gr.themes.Soft()) as demo:
    gr.Markdown("""
    ## 🤖 Chat with Anil R Studio powered Bot
    This chatbot is powered by the Gemma 3 1B model running locally through Ollama.
    """)
    
    with gr.Row():
        with gr.Column(scale=4):
            chatbot = gr.Chatbot(
                height=600,
                show_copy_button=True,
                show_share_button=True,
                type="messages"  # Using the new message format
            )
            with gr.Row():
                msg = gr.Textbox(
                    placeholder="Type your message here...",
                    label="Your Message",
                    scale=8,
                    show_label=False
                )
                send_btn = gr.Button("Send", scale=1)

    def respond(message: str, history: List[Dict[str, str]]) -> Tuple[List[Dict[str, str]], str]:
        """Handle the chat response with loading state."""
        if not message.strip():
            return history, ""
        return chat_with_ollama(history, message)

    # Set up the event handlers
    send_btn.click(
        fn=respond,
        inputs=[msg, chatbot],
        outputs=[chatbot, msg],
        api_name="chat"
    )
    
    msg.submit(
        fn=respond,
        inputs=[msg, chatbot],
        outputs=[chatbot, msg],
        api_name="chat_submit"
    )

    # Add a clear button
    clear_btn = gr.Button("Clear Chat")
    clear_btn.click(lambda: [], None, chatbot, queue=False)

if __name__ == "__main__":
    # Try different ports if 8089 is in use
    for port in range(8089, 8099):
        try:
            demo.launch(
                server_name="localhost",
                server_port=port,
                share=False,
                show_error=True
            )
            break
        except OSError:
            continue