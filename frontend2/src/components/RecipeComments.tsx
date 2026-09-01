import {
  AtSign,
  ChevronDown,
  ChevronUp,
  CornerDownRight,
  Image as ImageIcon,
  Link2,
  MoreHorizontal,
  Paperclip,
  Smile,
  ThumbsDown,
  ThumbsUp,
  ArrowUpDown,
} from "lucide-react";
import { useState } from "react";
import { useAuth } from "../auth/useAuth";

interface CommentReply {
  id: string;
  author: string;
  avatar: string;
  timestamp: string;
  text: string;
  upvotes: number;
  downvotes: number;
  userVote?: "up" | "down";
}

interface CommentItem {
  id: string;
  author: string;
  avatar: string;
  timestamp: string;
  text: string;
  upvotes: number;
  downvotes: number;
  userVote?: "up" | "down";
  replies: CommentReply[];
}

const INITIAL_COMMENTS: CommentItem[] = [
  {
    id: "c1",
    author: "Ziyech",
    avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&h=120&q=80",
    timestamp: "1 hour ago",
    text: "This recipe brings back nostalgic family dinners! I tweaked the simmering time slightly and the sauce reduced to pure perfection. The aroma of cardamom is incredible.",
    upvotes: 23,
    downvotes: 2,
    replies: [
      {
        id: "r1",
        author: "Shakira",
        avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=120&h=120&q=80",
        timestamp: "23 minutes ago",
        text: "Totally agree about simmering a bit longer. Adding fresh crushed coriander right at the end also elevated the whole dish!",
        upvotes: 15,
        downvotes: 1,
      },
      {
        id: "r2",
        author: "Ryan Timber",
        avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80",
        timestamp: "15 minutes ago",
        text: "Did you use regular coconut milk or coconut cream? I found coconut cream gave it a silkier texture.",
        upvotes: 3,
        downvotes: 0,
      },
    ],
  },
  {
    id: "c2",
    author: "McTominay",
    avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80",
    timestamp: "3 hours ago",
    text: "Cooked this for Sunday dinner and the whole family loved it. Super simple instructions to follow, even for beginner home cooks.",
    upvotes: 23,
    downvotes: 3,
    replies: [],
  },
];

export function RecipeComments() {
  const { user } = useAuth();
  const [comments, setComments] = useState<CommentItem[]>(INITIAL_COMMENTS);
  const [inputText, setInputText] = useState("");
  const [sortBy, setSortBy] = useState<"recent" | "top">("recent");
  const [activeReplyId, setActiveReplyId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState("");
  const [expandedReplies, setExpandedReplies] = useState<Record<string, boolean>>({
    c1: true,
  });

  const totalCommentCount = comments.reduce(
    (acc, c) => acc + 1 + c.replies.length,
    0
  );

  const handleAddComment = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) return;

    const newComment: CommentItem = {
      id: `c_${Date.now()}`,
      author: user?.name || "You",
      avatar:
        user?.avatar_url ||
        "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&h=120&q=80",
      timestamp: "Just now",
      text: inputText.trim(),
      upvotes: 0,
      downvotes: 0,
      replies: [],
    };

    setComments([newComment, ...comments]);
    setInputText("");
  };

  const handleAddReply = (commentId: string) => {
    if (!replyText.trim()) return;

    const newReply: CommentReply = {
      id: `r_${Date.now()}`,
      author: user?.name || "You",
      avatar:
        user?.avatar_url ||
        "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&h=120&q=80",
      timestamp: "Just now",
      text: replyText.trim(),
      upvotes: 0,
      downvotes: 0,
    };

    setComments((prev) =>
      prev.map((c) => {
        if (c.id === commentId) {
          return {
            ...c,
            replies: [...c.replies, newReply],
          };
        }
        return c;
      })
    );

    setExpandedReplies((prev) => ({ ...prev, [commentId]: true }));
    setReplyText("");
    setActiveReplyId(null);
  };

  const handleVoteComment = (commentId: string, type: "up" | "down") => {
    setComments((prev) =>
      prev.map((c) => {
        if (c.id !== commentId) return c;
        const currentVote = c.userVote;
        let up = c.upvotes;
        let down = c.downvotes;

        if (currentVote === type) {
          // undo vote
          if (type === "up") up--;
          if (type === "down") down--;
          return { ...c, upvotes: up, downvotes: down, userVote: undefined };
        } else {
          if (currentVote === "up") up--;
          if (currentVote === "down") down--;
          if (type === "up") up++;
          if (type === "down") down++;
          return { ...c, upvotes: up, downvotes: down, userVote: type };
        }
      })
    );
  };

  const handleVoteReply = (
    commentId: string,
    replyId: string,
    type: "up" | "down"
  ) => {
    setComments((prev) =>
      prev.map((c) => {
        if (c.id !== commentId) return c;
        return {
          ...c,
          replies: c.replies.map((r) => {
            if (r.id !== replyId) return r;
            const currentVote = r.userVote;
            let up = r.upvotes;
            let down = r.downvotes;

            if (currentVote === type) {
              if (type === "up") up--;
              if (type === "down") down--;
              return { ...r, upvotes: up, downvotes: down, userVote: undefined };
            } else {
              if (currentVote === "up") up--;
              if (currentVote === "down") down--;
              if (type === "up") up++;
              if (type === "down") down++;
              return { ...r, upvotes: up, downvotes: down, userVote: type };
            }
          }),
        };
      })
    );
  };

  const toggleReplies = (commentId: string) => {
    setExpandedReplies((prev) => ({
      ...prev,
      [commentId]: !prev[commentId],
    }));
  };

  const sortedComments = [...comments].sort((a, b) => {
    if (sortBy === "top") {
      return b.upvotes - a.upvotes;
    }
    return 0; // Default chronological
  });

  return (
    <section className="mt-14 rounded-2xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 p-6 sm:p-8 shadow-xs font-sans transition-colors duration-300">
      
      {/* Top Comment Input Box */}
      <form onSubmit={handleAddComment} className="space-y-4">
        <div className="flex gap-4 items-start">
          <div className="w-10 h-10 rounded-full bg-caramel/10 border border-caramel/20 flex items-center justify-center text-caramel font-bold text-sm shrink-0 overflow-hidden">
            {user?.avatar_url ? (
              <img
                src={user.avatar_url}
                alt={user?.name || "User"}
                className="w-full h-full object-cover"
              />
            ) : (
              <span>{user?.name ? user.name[0].toUpperCase() : "C"}</span>
            )}
          </div>

          <div className="flex-1 rounded-2xl border border-gray-200 dark:border-stone-800 bg-gray-50/50 dark:bg-[#120905]/40 p-4 transition-all focus-within:border-caramel/40 focus-within:bg-white dark:focus-within:bg-[#120905] focus-within:shadow-xs">
            <textarea
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="Share your mind..."
              rows={3}
              className="w-full bg-transparent text-sm text-ink dark:text-parchment placeholder-gray-400 focus:outline-hidden resize-none leading-relaxed"
            />

            {/* Input Toolbar */}
            <div className="flex items-center justify-between pt-2 border-t border-gray-100 dark:border-stone-850/60 mt-2">
              <div className="flex items-center gap-1 sm:gap-2 text-gray-400">
                <button
                  type="button"
                  title="Attach link"
                  className="p-1.5 hover:text-caramel hover:bg-caramel/5 rounded-lg transition-colors cursor-pointer"
                >
                  <Link2 size={16} />
                </button>
                <button
                  type="button"
                  title="Add image"
                  className="p-1.5 hover:text-caramel hover:bg-caramel/5 rounded-lg transition-colors cursor-pointer"
                >
                  <ImageIcon size={16} />
                </button>
                <button
                  type="button"
                  title="Add GIF"
                  className="px-1.5 py-0.5 text-[10px] font-extrabold border border-current rounded hover:text-caramel hover:bg-caramel/5 transition-colors cursor-pointer"
                >
                  GIF
                </button>
                <button
                  type="button"
                  title="Insert emoji"
                  className="p-1.5 hover:text-caramel hover:bg-caramel/5 rounded-lg transition-colors cursor-pointer"
                >
                  <Smile size={16} />
                </button>
                <button
                  type="button"
                  title="Mention someone"
                  className="p-1.5 hover:text-caramel hover:bg-caramel/5 rounded-lg transition-colors cursor-pointer"
                >
                  <AtSign size={16} />
                </button>
              </div>

              <button
                type="submit"
                disabled={!inputText.trim()}
                className="px-5 py-2 rounded-full bg-caramel hover:bg-caramel/90 disabled:opacity-40 disabled:cursor-not-allowed text-white text-xs font-bold transition-all shadow-xs cursor-pointer active:scale-95"
              >
                Post
              </button>
            </div>
          </div>
        </div>
      </form>

      {/* Header with Comment count & Sort Filter */}
      <div className="mt-8 mb-6 flex items-center justify-between border-b border-gray-100 dark:border-stone-850 pb-4">
        <div className="flex items-center gap-2.5">
          <h3 className="font-serif text-xl font-bold text-ink dark:text-parchment">
            Comments
          </h3>
          <span className="bg-caramel/15 text-caramel text-xs font-extrabold px-2.5 py-0.5 rounded-full">
            {totalCommentCount}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setSortBy(sortBy === "recent" ? "top" : "recent")}
            className="flex items-center gap-1.5 text-xs font-semibold text-gray-500 dark:text-gray-400 hover:text-ink dark:hover:text-parchment px-3 py-1.5 rounded-lg border border-gray-200 dark:border-stone-800 transition-colors cursor-pointer"
          >
            <ArrowUpDown size={13} className="text-caramel" />
            <span>{sortBy === "recent" ? "Most Recent" : "Top Rated"}</span>
            <ChevronDown size={14} className="opacity-60" />
          </button>
        </div>
      </div>

      {/* Comments Feed */}
      <div className="space-y-8">
        {sortedComments.map((comment) => {
          const hasReplies = comment.replies.length > 0;
          const isRepliesExpanded = expandedReplies[comment.id] ?? true;

          return (
            <div key={comment.id} className="space-y-4">
              {/* Main Parent Comment */}
              <div className="flex items-start gap-3.5 group">
                <img
                  src={comment.avatar}
                  alt={comment.author}
                  className="w-10 h-10 rounded-full object-cover shrink-0 ring-2 ring-gray-100 dark:ring-stone-800"
                />

                <div className="flex-1 space-y-1.5">
                  {/* Author Header */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-ink dark:text-white">
                        {comment.author}
                      </span>
                      <span className="text-xs text-gray-400 font-medium">
                        {comment.timestamp}
                      </span>
                    </div>

                    <button
                      title="More options"
                      className="text-gray-400 hover:text-ink dark:hover:text-parchment p-1 rounded transition-colors cursor-pointer"
                    >
                      <MoreHorizontal size={15} />
                    </button>
                  </div>

                  {/* Comment Body */}
                  <p className="text-xs sm:text-sm text-gray-700 dark:text-gray-300 leading-relaxed max-w-3xl">
                    {comment.text}
                  </p>

                  {/* Comment Actions (Upvote, Downvote, Reply) */}
                  <div className="flex items-center gap-4 pt-1 text-xs font-semibold text-gray-500 dark:text-gray-400">
                    <button
                      onClick={() => handleVoteComment(comment.id, "up")}
                      className={`flex items-center gap-1.5 transition-colors cursor-pointer ${
                        comment.userVote === "up"
                          ? "text-caramel font-bold"
                          : "hover:text-caramel"
                      }`}
                    >
                      <ThumbsUp size={14} className={comment.userVote === "up" ? "fill-caramel" : ""} />
                      <span>{comment.upvotes}</span>
                    </button>

                    <button
                      onClick={() => handleVoteComment(comment.id, "down")}
                      className={`flex items-center gap-1.5 transition-colors cursor-pointer ${
                        comment.userVote === "down"
                          ? "text-red-500 font-bold"
                          : "hover:text-red-500"
                      }`}
                    >
                      <ThumbsDown size={14} className={comment.userVote === "down" ? "fill-red-500" : ""} />
                      <span>{comment.downvotes}</span>
                    </button>

                    <button
                      onClick={() =>
                        setActiveReplyId(
                          activeReplyId === comment.id ? null : comment.id
                        )
                      }
                      className="hover:text-caramel transition-colors cursor-pointer"
                    >
                      Reply
                    </button>

                    {hasReplies && (
                      <button
                        onClick={() => toggleReplies(comment.id)}
                        className="flex items-center gap-1 text-caramel hover:underline transition-all cursor-pointer font-bold ml-1"
                      >
                        <span>Reply ({comment.replies.length})</span>
                        {isRepliesExpanded ? (
                          <ChevronUp size={14} />
                        ) : (
                          <ChevronDown size={14} />
                        )}
                      </button>
                    )}
                  </div>
                </div>
              </div>

              {/* In-line Reply Input */}
              {activeReplyId === comment.id && (
                <div className="ml-12 pl-4 border-l-2 border-caramel/20 py-2">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={replyText}
                      onChange={(e) => setReplyText(e.target.value)}
                      placeholder={`Reply to ${comment.author}...`}
                      className="flex-1 text-xs px-3.5 py-2 rounded-xl bg-gray-50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                    />
                    <button
                      onClick={() => handleAddReply(comment.id)}
                      className="px-4 py-1.5 bg-caramel text-white font-bold text-xs rounded-xl hover:bg-caramel/90 transition-colors cursor-pointer"
                    >
                      Reply
                    </button>
                  </div>
                </div>
              )}

              {/* Nested Replies with Threading Connector Lines */}
              {hasReplies && isRepliesExpanded && (
                <div className="ml-5 sm:ml-6 pl-6 border-l-2 border-gray-200 dark:border-stone-850 space-y-6 pt-2">
                  {comment.replies.map((reply) => (
                    <div key={reply.id} className="relative flex items-start gap-3.5 group">
                      {/* Curved Connector Indicator */}
                      <div className="absolute -left-6 top-3 w-4 h-4 border-b-2 border-gray-200 dark:border-stone-850 rounded-bl-lg pointer-events-none" />

                      <img
                        src={reply.avatar}
                        alt={reply.author}
                        className="w-8 h-8 rounded-full object-cover shrink-0 ring-2 ring-gray-100 dark:ring-stone-800 mt-0.5"
                      />

                      <div className="flex-1 space-y-1">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <span className="font-bold text-xs sm:text-sm text-ink dark:text-white">
                              {reply.author}
                            </span>
                            <span className="text-[11px] text-gray-400 font-medium">
                              {reply.timestamp}
                            </span>
                          </div>

                          <button
                            title="More options"
                            className="text-gray-400 hover:text-ink dark:hover:text-parchment p-1 rounded transition-colors cursor-pointer"
                          >
                            <MoreHorizontal size={14} />
                          </button>
                        </div>

                        <p className="text-xs sm:text-sm text-gray-600 dark:text-gray-300 leading-relaxed">
                          {reply.text}
                        </p>

                        {/* Reply Actions */}
                        <div className="flex items-center gap-4 pt-1 text-xs font-semibold text-gray-500 dark:text-gray-400">
                          <button
                            onClick={() =>
                              handleVoteReply(comment.id, reply.id, "up")
                            }
                            className={`flex items-center gap-1.5 transition-colors cursor-pointer ${
                              reply.userVote === "up"
                                ? "text-caramel font-bold"
                                : "hover:text-caramel"
                            }`}
                          >
                            <ThumbsUp
                              size={13}
                              className={reply.userVote === "up" ? "fill-caramel" : ""}
                            />
                            <span>{reply.upvotes}</span>
                          </button>

                          <button
                            onClick={() =>
                              handleVoteReply(comment.id, reply.id, "down")
                            }
                            className={`flex items-center gap-1.5 transition-colors cursor-pointer ${
                              reply.userVote === "down"
                                ? "text-red-500 font-bold"
                                : "hover:text-red-500"
                            }`}
                          >
                            <ThumbsDown
                              size={13}
                              className={
                                reply.userVote === "down" ? "fill-red-500" : ""
                              }
                            />
                            {reply.downvotes > 0 && <span>{reply.downvotes}</span>}
                          </button>

                          <button
                            onClick={() => {
                              setActiveReplyId(comment.id);
                              setReplyText(`@${reply.author} `);
                            }}
                            className="hover:text-caramel transition-colors cursor-pointer"
                          >
                            Reply
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
