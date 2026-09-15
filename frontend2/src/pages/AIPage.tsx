import { useState, useRef, useEffect } from "react";
import {
  Utensils,
  Package,
  MessageSquare,
  Sparkles,
  Send,
  ChefHat,
  Bot
} from "lucide-react";

type Mode = "meal_planner" | "leftover_planner" | "general_chat";

interface Message {
  id: string;
  role: "user" | "ai";
  content: string;
  mode: Mode;
}

const MODES = [
  {
    id: "meal_planner",
    label: "Meal Planner",
    icon: Utensils,
    description: "Plan your weekly macros and meals.",
    color: "from-emerald-400 to-teal-500",
    bgLight: "bg-emerald-50",
    bgDark: "dark:bg-emerald-950/20",
    textColor: "text-emerald-600 dark:text-emerald-400"
  },
  {
    id: "leftover_planner",
    label: "Leftover Planner",
    icon: Package,
    description: "Turn fridge leftovers into feasts.",
    color: "from-amber-400 to-orange-500",
    bgLight: "bg-amber-50",
    bgDark: "dark:bg-amber-950/20",
    textColor: "text-amber-600 dark:text-amber-400"
  },
  {
    id: "general_chat",
    label: "General Chat",
    icon: MessageSquare,
    description: "Ask anything about cooking.",
    color: "from-caramel to-orange-400",
    bgLight: "bg-orange-50",
    bgDark: "dark:bg-orange-950/20",
    textColor: "text-caramel dark:text-caramel"
  },
] as const;

export function AIPage() {
  const [activeMode, setActiveMode] = useState<Mode>("general_chat");
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "welcome-1",
      role: "ai",
      content: "Hello! I'm your Caramel AI Chef. How can I help you in the kitchen today?",
      mode: "general_chat"
    }
  ]);
  const [isTyping, setIsTyping] = useState(false);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to latest message
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isTyping]);

  const handleSendMessage = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!input.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content: input.trim(),
      mode: activeMode,
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setIsTyping(true);

    // Simulate AI response
    setTimeout(() => {
      let aiResponseContent = "";
      if (activeMode === "meal_planner") {
        aiResponseContent = "I can certainly help you plan your meals! Could you tell me about your dietary preferences and calorie goals?";
      } else if (activeMode === "leftover_planner") {
        aiResponseContent = "Let's make something delicious! What ingredients do you have left in your fridge?";
      } else {
        aiResponseContent = "That's a great question! Cooking is all about balancing flavors. Let me know if you need specific tips.";
      }

      const aiMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: "ai",
        content: aiResponseContent,
        mode: activeMode,
      };

      setMessages((prev) => [...prev, aiMessage]);
      setIsTyping(false);
    }, 1500);
  };

  const activeModeConfig = MODES.find((m) => m.id === activeMode);

  return (
    <div className="flex flex-col lg:flex-row min-h-[calc(100vh-73px)] bg-gray-50 dark:bg-[#120905]">
      {/* Sidebar Mode Selector */}
      <aside className="w-full lg:w-80 shrink-0 border-b lg:border-b-0 lg:border-r border-taupe/15 dark:border-stone-800 bg-white dark:bg-[#160a06] flex flex-col relative z-10 transition-colors">
        <div className="p-6">
          <div className="flex items-center gap-3 mb-8">
            <div className="flex items-center justify-center h-10 w-10 rounded-2xl bg-gradient-to-br from-caramel to-orange-500 text-white shadow-lg shadow-caramel/20">
              <Sparkles size={20} className="fill-white/20" />
            </div>
            <div>
              <h1 className="font-display text-xl text-ink dark:text-white">AI Kitchen</h1>
              <p className="text-xs font-medium text-gray-500 dark:text-stone-400">Your personal culinary assistant</p>
            </div>
          </div>

          <h2 className="text-xs font-bold uppercase tracking-wider text-gray-400 dark:text-stone-500 mb-4 px-1">
            Assistant Mode
          </h2>

          <div className="flex flex-row lg:flex-col gap-3 overflow-x-auto lg:overflow-x-visible pb-4 lg:pb-0 scrollbar-hide">
            {MODES.map((mode) => {
              const Icon = mode.icon;
              const isActive = activeMode === mode.id;

              return (
                <button
                  key={mode.id}
                  onClick={() => setActiveMode(mode.id as Mode)}
                  className={`flex items-start gap-4 p-4 rounded-2xl transition-all duration-300 min-w-[240px] lg:min-w-0 text-left border cursor-pointer ${isActive
                    ? 'bg-white dark:bg-stone-900 border-caramel/30 dark:border-caramel/30 shadow-md shadow-caramel/5 ring-1 ring-caramel/20 scale-[1.02]'
                    : 'bg-transparent border-transparent hover:bg-gray-100 dark:hover:bg-stone-800 hover:scale-[1.01]'
                    }`}
                >
                  <div
                    className={`mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl transition-colors ${isActive
                      ? 'bg-gradient-to-br text-white shadow-sm ' + mode.color
                      : "bg-gray-100 dark:bg-stone-800 text-gray-500 dark:text-stone-400"
                      }`}
                  >
                    <Icon size={18} />
                  </div>
                  <div>
                    <h3
                      className={`font-semibold text-sm ${isActive ? "text-ink dark:text-white" : "text-gray-700 dark:text-gray-300"
                        }`}
                    >
                      {mode.label}
                    </h3>
                    <p
                      className={`text-xs mt-1 leading-relaxed ${isActive ? "text-gray-600 dark:text-gray-400" : "text-gray-500 dark:text-stone-500"
                        }`}
                    >
                      {mode.description}
                    </p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </aside>

      {/* Main Chat Area */}
      <main className="flex-1 flex flex-col relative min-h-0 bg-gray-50 dark:bg-[#120905]">
        {/* Dynamic Header based on active mode */}
        <header className="absolute top-0 inset-x-0 h-24 bg-gradient-to-b from-gray-50 via-gray-50/80 to-transparent dark:from-[#120905] dark:via-[#120905]/80 dark:to-transparent z-10 pointer-events-none" />

        <div className="flex-1 overflow-y-auto px-4 sm:px-6 lg:px-12 pt-8 pb-32">
          {messages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center max-w-md mx-auto space-y-6 opacity-0 animate-in fade-in zoom-in duration-500">
              <div className={`h-24 w-24 rounded-[2rem] bg-gradient-to-br ${activeModeConfig?.color} text-white flex items-center justify-center shadow-2xl rotate-3`}>
                {activeModeConfig && <activeModeConfig.icon size={40} strokeWidth={1.5} />}
              </div>
              <div>
                <h2 className="text-2xl font-display text-ink dark:text-white mb-2">
                  {activeModeConfig?.label}
                </h2>
                <p className="text-gray-500 dark:text-stone-400 text-sm">
                  {activeModeConfig?.description} Start a conversation below.
                </p>
              </div>
            </div>
          ) : (
            <div className="space-y-8 max-w-4xl mx-auto">
              {messages.map((msg) => {
                const isUser = msg.role === "user";
                const isAi = msg.role === "ai";

                return (
                  <div
                    key={msg.id}
                    className={`flex items-end gap-3 sm:gap-4 ${isUser ? "justify-end" : "justify-start"
                      }`}
                  >
                    {isAi && (
                      <div className="flex h-8 w-8 sm:h-10 sm:w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-caramel to-orange-500 text-white shadow-md">
                        <Bot size={18} />
                      </div>
                    )}

                    <div
                      className={`relative max-w-[85%] sm:max-w-[75%] px-5 py-3.5 rounded-3xl text-sm leading-relaxed ${isUser
                        ? "bg-ink dark:bg-stone-800 text-white rounded-br-md shadow-md"
                        : "bg-white dark:bg-[#1c0f0a] border border-taupe/15 dark:border-stone-800 text-ink dark:text-gray-200 rounded-bl-md shadow-xs"
                        }`}
                    >
                      <p>{msg.content}</p>
                    </div>

                    {isUser && (
                      <div className="flex h-8 w-8 sm:h-10 sm:w-10 shrink-0 items-center justify-center rounded-full bg-gray-200 dark:bg-stone-800 text-gray-500 dark:text-gray-400">
                        <ChefHat size={18} />
                      </div>
                    )}
                  </div>
                );
              })}

              {isTyping && (
                <div className="flex items-end gap-3 sm:gap-4 justify-start">
                  <div className="flex h-8 w-8 sm:h-10 sm:w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-caramel to-orange-500 text-white shadow-md">
                    <Bot size={18} />
                  </div>
                  <div className="relative bg-white dark:bg-[#1c0f0a] border border-taupe/15 dark:border-stone-800 px-5 py-4 rounded-3xl rounded-bl-md shadow-xs flex gap-1.5">
                    <div className="w-1.5 h-1.5 rounded-full bg-caramel/60 animate-bounce" style={{ animationDelay: "0ms" }} />
                    <div className="w-1.5 h-1.5 rounded-full bg-caramel/60 animate-bounce" style={{ animationDelay: "150ms" }} />
                    <div className="w-1.5 h-1.5 rounded-full bg-caramel/60 animate-bounce" style={{ animationDelay: "300ms" }} />
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        {/* Input Area */}
        <div className="absolute bottom-0 inset-x-0 p-4 sm:p-6 lg:px-12 bg-gradient-to-t from-gray-50 via-gray-50 to-transparent dark:from-[#120905] dark:via-[#120905] pointer-events-none">
          <div className="max-w-4xl mx-auto pointer-events-auto pb-4">
            <form
              onSubmit={handleSendMessage}
              className="relative flex items-center bg-white dark:bg-stone-900 border border-taupe/20 dark:border-stone-700/60 rounded-full p-2 pr-2.5 shadow-xl shadow-caramel/5 transition-all duration-300 focus-within:ring-2 focus-within:ring-caramel/30 focus-within:border-caramel/50"
            >
              <div className="pl-4 pr-3 text-gray-400 dark:text-stone-500">
                {activeModeConfig && <activeModeConfig.icon size={20} />}
              </div>
              <input
                type="text"
                placeholder={`Message in ${activeModeConfig?.label}...`}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                className="flex-1 bg-transparent border-none focus:outline-none text-ink dark:text-white placeholder:text-gray-400 dark:placeholder:text-stone-500 text-sm h-10"
              />
              <button
                type="submit"
                disabled={!input.trim() || isTyping}
                className={`flex items-center justify-center h-10 w-10 sm:w-auto sm:px-4 rounded-full gap-2 transition-all duration-200 ${input.trim() && !isTyping
                  ? "bg-gradient-to-r from-caramel to-orange-500 text-white shadow-md hover:shadow-lg cursor-pointer transform hover:-translate-y-0.5"
                  : "bg-gray-100 dark:bg-stone-800 text-gray-400 dark:text-stone-600 cursor-not-allowed"
                  }`}
              >
                <span className="hidden sm:inline font-semibold text-sm">Send</span>
                <Send size={16} className={input.trim() && !isTyping ? "fill-white/20 -mt-0.5 ml-0.5" : ""} />
              </button>
            </form>

            <div className="text-center mt-3">
              <p className="text-[10px] text-gray-400 dark:text-stone-600 font-medium tracking-wide">
                AI Chef can make mistakes. Consider verifying important nutritional information.
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
