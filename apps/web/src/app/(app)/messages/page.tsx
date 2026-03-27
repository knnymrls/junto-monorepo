"use client";

import { useQuery, useMutation } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { Id } from "@junto/backend/convex/_generated/dataModel";
import { useCurrentMaker } from "@/hooks/use-current-maker";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar } from "@/components/avatar";
import { formatRelativeTime } from "@/lib/utils";
import { ArrowLeft, Send } from "lucide-react";
import { useState, useEffect, useRef } from "react";

export default function MessagesPage() {
  const { maker } = useCurrentMaker();
  const [selectedConversationId, setSelectedConversationId] =
    useState<Id<"conversations"> | null>(null);

  const conversations = useQuery(
    api.messages.listConversations,
    maker ? { makerId: maker._id } : "skip"
  );

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight">Messages</h1>

      {selectedConversationId && maker ? (
        <ChatView
          conversationId={selectedConversationId}
          makerId={maker._id}
          onBack={() => setSelectedConversationId(null)}
        />
      ) : (
        <div className="space-y-2">
          {conversations === undefined ? (
            <div className="space-y-2">
              {[1, 2, 3].map((i) => (
                <Card key={i} size="sm">
                  <CardContent>
                    <div className="animate-pulse flex items-center gap-3">
                      <div className="h-10 w-10 rounded-full bg-muted" />
                      <div className="flex-1 space-y-1.5">
                        <div className="h-4 w-24 rounded bg-muted" />
                        <div className="h-3 w-40 rounded bg-muted" />
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : conversations.length === 0 ? (
            <Card size="sm">
              <CardContent className="py-12 text-center">
                <p className="text-muted-foreground text-sm">
                  No messages yet. Start a conversation from someone&apos;s
                  profile!
                </p>
              </CardContent>
            </Card>
          ) : (
            conversations.map((conv) => (
              <button
                key={conv._id}
                onClick={() => setSelectedConversationId(conv._id)}
                className="w-full text-left"
              >
                <Card
                  size="sm"
                  className="hover:ring-foreground/20 hover:shadow-md transition-all cursor-pointer"
                >
                  <CardContent className="flex items-center gap-3">
                    <div className="relative">
                      <Avatar
                        src={conv.otherParticipant?.avatarUrl}
                        name={conv.otherParticipant?.name || "?"}
                        size="md"
                      />
                      {conv.unreadCount > 0 && (
                        <span className="absolute -top-0.5 -right-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-chart-2 text-[9px] font-bold text-white">
                          {conv.unreadCount}
                        </span>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <p className="font-medium text-sm truncate">
                          {conv.otherParticipant?.name}
                        </p>
                        <span className="text-xs text-muted-foreground">
                          {formatRelativeTime(conv.lastMessageAt)}
                        </span>
                      </div>
                      <p className="text-xs text-muted-foreground truncate">
                        {conv.lastMessagePreview}
                      </p>
                    </div>
                    {conv.isRequest && (
                      <span className="shrink-0 rounded-full bg-amber-500/10 px-2 py-0.5 text-[10px] font-medium text-amber-600">
                        Request
                      </span>
                    )}
                  </CardContent>
                </Card>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );
}

function ChatView({
  conversationId,
  makerId,
  onBack,
}: {
  conversationId: Id<"conversations">;
  makerId: Id<"makers">;
  onBack: () => void;
}) {
  const [messageText, setMessageText] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const messages = useQuery(api.messages.getMessages, { conversationId });
  const conversations = useQuery(api.messages.listConversations, { makerId });
  const conversation = conversations?.find((c) => c._id === conversationId);

  const sendMessage = useMutation(api.messages.sendMessage);
  const markRead = useMutation(api.messages.markConversationRead);

  useEffect(() => {
    markRead({ conversationId, makerId });
  }, [conversationId, makerId, markRead, messages?.length]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages?.length]);

  async function handleSend() {
    if (!messageText.trim() || !conversation?.otherParticipant) return;
    await sendMessage({
      senderId: makerId,
      recipientId: conversation.otherParticipant._id,
      content: messageText.trim(),
    });
    setMessageText("");
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon-sm" onClick={onBack}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <Avatar
          src={conversation?.otherParticipant?.avatarUrl}
          name={conversation?.otherParticipant?.name || "?"}
          size="sm"
        />
        <div>
          <p className="font-medium text-sm">
            {conversation?.otherParticipant?.name}
          </p>
        </div>
      </div>

      <div className="space-y-3 max-h-[60vh] overflow-y-auto rounded-lg bg-muted/30 p-4">
        {messages?.map((msg) => {
          const isMe = msg.senderId === makerId;
          return (
            <div
              key={msg._id}
              className={`flex ${isMe ? "justify-end" : "justify-start"}`}
            >
              <div
                className={`max-w-[70%] rounded-2xl px-4 py-2 text-sm ${
                  isMe
                    ? "bg-primary text-primary-foreground rounded-br-md"
                    : "bg-card ring-1 ring-foreground/10 rounded-bl-md"
                }`}
              >
                <p className="whitespace-pre-wrap">{msg.content}</p>
                <p
                  className={`mt-1 text-[10px] ${
                    isMe
                      ? "text-primary-foreground/60"
                      : "text-muted-foreground"
                  }`}
                >
                  {formatRelativeTime(msg.createdAt)}
                </p>
              </div>
            </div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      <div className="flex gap-2">
        <textarea
          value={messageText}
          onChange={(e) => setMessageText(e.target.value)}
          placeholder="Type a message..."
          className="flex-1 resize-none rounded-md border border-input bg-transparent px-3 py-2 text-sm outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
          rows={1}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              handleSend();
            }
          }}
        />
        <Button onClick={handleSend} disabled={!messageText.trim()}>
          <Send className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
