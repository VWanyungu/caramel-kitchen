import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { Bookmark, BookmarkCheck, Diamond, Layers, Lock, Sun } from "lucide-react";
import type { Collection } from "../pages/collections/types";
import { usePremiumModal } from "../context/PremiumModalContext";
import {
  isCollectionSaved,
  toggleSaveCollection,
  subscribeToSavedCollections,
} from "../lib/savedCollectionsStorage";

interface CollectionCardProps {
  collection: Collection;
  onSaveToggle?: (collectionId: string, isSaved: boolean) => void;
}

export function CollectionCard({ collection, onSaveToggle }: CollectionCardProps) {
  const { isPremium, openPremiumModal } = usePremiumModal();
  const itemCount = collection.items?.length || 0;
  const [saved, setSaved] = useState<boolean>(isCollectionSaved(collection.id));

  useEffect(() => {
    setSaved(isCollectionSaved(collection.id));
    const unsubscribe = subscribeToSavedCollections(() => {
      setSaved(isCollectionSaved(collection.id));
    });
    return unsubscribe;
  }, [collection.id]);

  const handleClick = (e: React.MouseEvent) => {
    if (collection.is_premium && !isPremium) {
      e.preventDefault();
      openPremiumModal({
        featureName: "Premium Collections",
        featureDescription:
          "Access exclusive, expert-curated recipe and video collections with a Caramel Premium plan.",
      });
    }
  };

  const handleSaveClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    const nowSaved = toggleSaveCollection(collection.id);
    setSaved(nowSaved);
    if (onSaveToggle) {
      onSaveToggle(collection.id, nowSaved);
    }
  };

  return (
    <Link
      to={`/collections/${collection.id}`}
      onClick={handleClick}
      className="group relative flex flex-col h-full overflow-hidden rounded-3xl bg-white dark:bg-stone-900 border border-taupe/20 dark:border-stone-800 shadow-sm hover:shadow-xl hover:border-caramel/40 transition-all duration-300 transform hover:-translate-y-1"
    >
      <div className="relative aspect-[4/3] w-full overflow-hidden bg-gray-100 dark:bg-stone-800">
        <img
          src={collection.cover_image_url}
          alt={collection.name}
          className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-80" />

        {/* Badges */}
        <div className="absolute top-4 left-4 flex flex-col gap-2 items-start">
          {collection.is_premium && (
            <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-amber-500/90 text-white text-[10px] font-bold tracking-wider uppercase backdrop-blur-md shadow-sm">
              <Diamond size={10} className="fill-white" />
              Premium
            </span>
          )}
          {collection.is_seasonal && (
            <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/90 text-white text-[10px] font-bold tracking-wider uppercase backdrop-blur-md shadow-sm">
              <Sun size={10} />
              {collection.season_name}
            </span>
          )}
        </div>

        {/* Action icons container on top right */}
        <div className="absolute top-4 right-4 flex items-center gap-2 z-10">
          {collection.is_premium && !isPremium && (
            <div className="h-8 w-8 rounded-full bg-black/40 backdrop-blur-md flex items-center justify-center shadow-sm">
              <Lock size={14} className="text-white" />
            </div>
          )}

          <button
            type="button"
            onClick={handleSaveClick}
            title={saved ? "Remove from saved collections" : "Save collection"}
            className={`h-8 w-8 rounded-full backdrop-blur-md flex items-center justify-center transition-all duration-200 cursor-pointer shadow-md ${
              saved
                ? "bg-caramel text-white scale-105"
                : "bg-black/40 hover:bg-caramel text-white hover:scale-105"
            }`}
          >
            {saved ? (
              <BookmarkCheck size={15} className="fill-white" />
            ) : (
              <Bookmark size={15} />
            )}
          </button>
        </div>

        <div className="absolute bottom-4 left-4 right-4 flex items-center justify-between text-white">
          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-black/40 backdrop-blur-md text-xs font-medium">
            <Layers size={14} className="text-gray-300" />
            <span>{itemCount} items</span>
          </div>
        </div>
      </div>

      <div className="flex flex-col p-5 grow">
        <h3 className="font-display text-xl font-bold text-ink dark:text-white line-clamp-1 mb-1">
          {collection.name}
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 line-clamp-2 grow leading-relaxed">
          {collection.description}
        </p>
      </div>
    </Link>
  );
}
