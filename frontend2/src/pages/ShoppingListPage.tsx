import { useState, useEffect } from "react";
import {
  Trash2,
  Copy,
  Download,
  Save,
  Plus,
  Minus,
  Search,
  ChevronDown,
  ChevronUp,
  ClipboardList,
  BookOpen,
  CheckSquare,
  Square,
} from "lucide-react";
import { Button } from "../components/ui";
import { PLACEHOLDER_RECIPES } from "../features/browse/placeholderRecipes";

interface ShoppingItem {
  id: string | number;
  name: string;
  quantity: number;
  unit: string;
  price: number;
  checked: boolean;
}

interface SavedList {
  id: string;
  name: string;
  items: ShoppingItem[];
}

// const CATEGORIES = [
//   { key: "baked_goods", label: "Baked Goods" },
//   { key: "rice_dishes", label: "Rice Dishes" },
//   { key: "soups_stews", label: "Soups & Stews" },
//   { key: "breakfast", label: "Breakfast" },
//   { key: "fish_seafood", label: "Fish & Seafood" },
//   { key: "other", label: "Other" }
// ];

export function ShoppingListPage() {
  // 1. Core shopping list state (persisted to localStorage)
  const [items, setItems] = useState<ShoppingItem[]>(() => {
    const saved = localStorage.getItem("shopping_list_items");
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        console.error("Failed to parse shopping list items:", e);
      }
    }
    return [
      {
        id: 1,
        name: "Puff pastry sheet",
        quantity: 1,
        unit: "whole",
        price: 150,
        checked: false,
      },
      {
        id: 2,
        name: "Granulated sugar",
        quantity: 1,
        unit: "cup",
        price: 50,
        checked: false,
      },
      {
        id: 3,
        name: "Heavy cream",
        quantity: 0.75,
        unit: "cup",
        price: 120,
        checked: false,
      },
      {
        id: 4,
        name: "Unsalted butter",
        quantity: 6,
        unit: "tbsp",
        price: 180,
        checked: false,
      },
    ];
  });

  // 2. Saved lists state (persisted to localStorage)
  const [savedLists, setSavedLists] = useState<SavedList[]>(() => {
    const saved = localStorage.getItem("saved_shopping_lists");
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        console.error("Failed to parse saved shopping lists:", e);
      }
    }
    return [];
  });

  // 3. UI states
  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const [showConfirmClear, setShowConfirmClear] = useState(false);
  const [expandedRecipeId, setExpandedRecipeId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");

  // 4. Custom item inputs
  const [customName, setCustomName] = useState("");
  const [customQty, setCustomQty] = useState<number>(1);
  const [customUnit, setCustomUnit] = useState("pcs");
  const [customPrice, setCustomPrice] = useState<number>(100);

  // 5. Save list form inputs
  const [listName, setListName] = useState("");
  const [recipePage, setRecipePage] = useState(1);

  // Sync to localStorage
  useEffect(() => {
    localStorage.setItem("shopping_list_items", JSON.stringify(items));
  }, [items]);

  useEffect(() => {
    localStorage.setItem("saved_shopping_lists", JSON.stringify(savedLists));
  }, [savedLists]);

  useEffect(() => {
    setRecipePage(1);
  }, [searchQuery]);

  // Toast handler helper
  const triggerToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => {
      setToastMsg((prev) => (prev === msg ? null : prev));
    }, 3000);
  };

  // Helper to generate dynamic deterministic mock prices for recipe imports
  const getMockPrice = (name: string): number => {
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    const base = 40 + (Math.abs(hash) % 210); // Price ranges between 40 and 250 Ksh
    return Math.round(base / 5) * 5; // Round to nearest 5 Ksh
  };

  // Shopping List logic
  const toggleChecked = (id: string | number) => {
    setItems(
      items.map((item) =>
        item.id === id ? { ...item, checked: !item.checked } : item,
      ),
    );
  };

  const updateQty = (id: string | number, newQty: number) => {
    const sanitizedQty = Math.max(0, parseFloat(newQty.toFixed(2)) || 0);
    setItems(
      items.map((item) =>
        item.id === id ? { ...item, quantity: sanitizedQty } : item,
      ),
    );
  };

  const incrementQty = (id: string | number) => {
    setItems(
      items.map((item) =>
        item.id === id
          ? { ...item, quantity: parseFloat((item.quantity + 1).toFixed(2)) }
          : item,
      ),
    );
  };

  const decrementQty = (id: string | number) => {
    setItems(
      items.map((item) => {
        if (item.id === id) {
          const nextQty = Math.max(0, item.quantity - 1);
          return { ...item, quantity: parseFloat(nextQty.toFixed(2)) };
        }
        return item;
      }),
    );
  };

  const removeItem = (id: string | number) => {
    setItems(items.filter((item) => item.id !== id));
  };

  const handleAddCustomItem = (e: React.FormEvent) => {
    e.preventDefault();
    if (!customName.trim()) return;

    const newItem: ShoppingItem = {
      id: `custom-item-${Date.now()}`,
      name: customName.trim(),
      quantity: Math.max(0.01, customQty),
      unit: customUnit.trim() || "pcs",
      price: Math.max(0, customPrice),
      checked: false,
    };

    setItems([...items, newItem]);
    setCustomName("");
    setCustomQty(1);
    setCustomUnit("pcs");
    setCustomPrice(100);
    triggerToast(`Added ${newItem.name} to the list!`);
  };

  // List actions
  // const handleSaveList = () => {
  //   localStorage.setItem("shopping_list_items", JSON.stringify(items));
  //   triggerToast("Shopping list saved successfully!");
  // };

  const handleClearList = () => {
    setItems([]);
    setShowConfirmClear(false);
    triggerToast("Shopping list cleared.");
  };

  const handleCopyList = async () => {
    if (items.length === 0) {
      triggerToast("List is empty. Add items first!");
      return;
    }

    const text = items
      .map(
        (item) =>
          `${item.checked ? "[x]" : "[ ]"} ${item.name} (${item.quantity} ${item.unit}) - Price: ${item.price} Ksh - Total: ${Math.round(item.quantity * item.price)} Ksh`,
      )
      .join("\n");

    const fullText = `My Shopping List\n----------------\n${text}\n----------------\nTotal Estimated Cost: ${Math.round(
      items.reduce((sum, item) => sum + item.price * item.quantity, 0),
    )} Ksh`;

    try {
      await navigator.clipboard.writeText(fullText);
      triggerToast("Shopping list copied to clipboard!");
    } catch {
      triggerToast("Failed to copy list.");
    }
  };

  const handleDownloadList = () => {
    if (items.length === 0) {
      triggerToast("List is empty. Add items first!");
      return;
    }

    const text = items
      .map(
        (item) =>
          `${item.checked ? "[x]" : "[ ]"} ${item.name} (${item.quantity} ${item.unit}) - Price: ${item.price} Ksh - Total: ${Math.round(item.quantity * item.price)} Ksh`,
      )
      .join("\n");

    const fullText = `My Shopping List\n----------------\n${text}\n----------------\nTotal Estimated Cost: ${Math.round(
      items.reduce((sum, item) => sum + item.price * item.quantity, 0),
    )} Ksh`;

    const blob = new Blob([fullText], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `shopping-list-${new Date().toISOString().slice(0, 10)}.txt`;
    link.click();
    URL.revokeObjectURL(url);
    triggerToast("Shopping list downloaded successfully!");
  };

  // Saved list actions
  const handleSaveCurrentList = (e: React.FormEvent) => {
    e.preventDefault();
    if (!listName.trim()) {
      triggerToast("Please enter a list name.");
      return;
    }
    if (items.length === 0) {
      triggerToast("Your list is empty. Add items to save.");
      return;
    }

    const newList: SavedList = {
      id: `saved-list-${Date.now()}`,
      name: listName.trim(),
      items: [...items],
    };

    setSavedLists([newList, ...savedLists]);
    setListName("");
    triggerToast(`List "${newList.name}" saved successfully!`);
  };

  const handleLoadSavedList = (list: SavedList) => {
    setItems(list.items);
    triggerToast(`Loaded shopping list "${list.name}"!`);
  };

  const handleDeleteSavedList = (id: string) => {
    setSavedLists(savedLists.filter((list) => list.id !== id));
    triggerToast("Saved list deleted.");
  };

  const importRecipeIngredients = (
    recipeTitle: string,
    recipeIngredients: any[],
  ) => {
    const newItems: ShoppingItem[] = [...items];

    recipeIngredients.forEach((ing) => {
      const match = newItems.find(
        (item) =>
          item.name.trim().toLowerCase() === ing.name.trim().toLowerCase(),
      );

      if (match) {
        match.quantity = parseFloat(
          (match.quantity + (ing.quantity || 1)).toFixed(2),
        );
      } else {
        newItems.push({
          id: `imported-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
          name: ing.name,
          quantity: ing.quantity || 1,
          unit: ing.unit || "whole",
          price: getMockPrice(ing.name),
          checked: false,
        });
      }
    });

    setItems(newItems);
    triggerToast(`Added ingredients from "${recipeTitle}" to list.`);
  };

  // Standard recipes
  const allRecipes = PLACEHOLDER_RECIPES.map((r) => ({
    ...r,
    isCustom: false,
  }));

  const filteredRecipes = allRecipes.filter((r) =>
    r.title.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  const totalPages = Math.ceil(filteredRecipes.length / 5);
  const paginatedRecipes = filteredRecipes.slice(
    (recipePage - 1) * 5,
    recipePage * 5,
  );

  const totalCost = items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0,
  );
  const checkedItems = items.filter((item) => item.checked).length;

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-[#120905] text-ink dark:text-parchment py-12 px-4 sm:px-8 lg:px-24 xl:px-44 transition-colors duration-300 font-sans">
      {/* Toast Notification */}
      {toastMsg && (
        <div className="fixed top-6 right-6 z-50 bg-[#1d120a] dark:bg-parchment text-white dark:text-ink px-4 py-3 rounded-xl shadow-lg border border-taupe/15 flex items-center gap-2 animate-in fade-in slide-in-from-top-4 duration-300">
          <CheckSquare size={18} className="text-caramel" />
          <span className="text-sm font-semibold">{toastMsg}</span>
        </div>
      )}

      <div className="mx-auto max-w-7xl">
        {/* Page Title */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
          <div className="flex items-center gap-3">
            {/* <div className="p-2.5 bg-caramel/10 dark:bg-caramel/20 rounded-2xl text-caramel">
              <ClipboardList size={26} />
            </div> */}
            <div>
              <h1 className="font-serif text-3xl font-bold tracking-tight text-ink dark:text-parchment">
                Shopping List
              </h1>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Organize your kitchen ingredients and plan your grocery shopping
              </p>
            </div>
          </div>

          {/* List Action Buttons */}
          {items.length > 0 && (
            <div className="flex flex-wrap gap-2">
              <Button
                variant="outline"
                size="sm"
                icon={<Copy size={14} />}
                onClick={handleCopyList}
                title="Copy checklist text to clipboard"
                className="!text-xs cursor-pointer hover:bg-gray-100 dark:hover:bg-stone-850"
              >
                Copy List
              </Button>
              <Button
                variant="outline"
                size="sm"
                icon={<Download size={14} />}
                onClick={handleDownloadList}
                title="Download list as text file"
                className="!text-xs cursor-pointer hover:bg-gray-100 dark:hover:bg-stone-850"
              >
                Download
              </Button>
              {/* <Button
                variant="outline"
                size="sm"
                icon={<Save size={14} />}
                onClick={handleSaveList}
                title="Save current state"
                className="!text-xs cursor-pointer hover:bg-gray-100 dark:hover:bg-stone-850"
              >
                Save
              </Button> */}

              {/* Clear confirmation toggle */}
              {showConfirmClear ? (
                <div className="flex items-center gap-1.5 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-955 px-2 py-1 rounded-full">
                  <span className="text-[10px] font-bold text-red-600 dark:text-red-400 pl-1.5">
                    Are you sure?
                  </span>
                  <button
                    onClick={handleClearList}
                    className="text-xs text-white bg-red-600 hover:bg-red-700 px-2.5 py-0.5 rounded-full cursor-pointer font-bold"
                  >
                    Yes
                  </button>
                  <button
                    onClick={() => setShowConfirmClear(false)}
                    className="text-xs text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 px-2 py-0.5 rounded-full hover:bg-gray-100 dark:hover:bg-stone-850 cursor-pointer"
                  >
                    No
                  </button>
                </div>
              ) : (
                <Button
                  variant="outline"
                  size="sm"
                  icon={<Trash2 size={14} />}
                  onClick={() => setShowConfirmClear(true)}
                  title="Clear all ingredients"
                  className="!text-xs !text-red-500 border-red-200 hover:!bg-red-50 dark:border-red-950/40 dark:hover:!bg-red-950/20 cursor-pointer"
                >
                  Clear List
                </Button>
              )}
            </div>
          )}
        </div>

        {items.length === 0 ? (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
            {/* Empty list screen */}
            <div className="lg:col-span-8 bg-white dark:bg-[#1d120a] rounded-3xl p-12 text-center shadow-xs border border-taupe/10">
              <ClipboardList
                size={56}
                className="mx-auto text-gray-300 dark:text-stone-700 mb-4"
              />
              <h2 className="text-xl font-bold text-ink dark:text-parchment mb-2">
                Your Shopping List is Empty
              </h2>
              <p className="text-gray-500 dark:text-gray-400 max-w-md mx-auto mb-6 text-sm">
                Add custom ingredients using the form or import ingredients from
                existing recipes in the sidebar.
              </p>
              <form
                onSubmit={handleAddCustomItem}
                className="w-full mx-auto bg-gray-50 dark:bg-stone-900/40 p-5 rounded-2xl border border-taupe/15 space-y-4 text-left"
              >
                <h3 className="font-serif text-sm font-semibold text-ink dark:text-parchment font-bold">
                  Add Custom Ingredient
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-12 gap-3">
                  <div className="sm:col-span-4">
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                      Item Name
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Fresh milk"
                      value={customName}
                      onChange={(e) => setCustomName(e.target.value)}
                      className="w-full text-sm bg-white dark:bg-[#120905] border border-taupe/15 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none"
                    />
                  </div>
                  <div className="sm:col-span-3">
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                      Qty
                    </label>
                    <input
                      type="number"
                      step="any"
                      min="0.01"
                      value={customQty}
                      onChange={(e) =>
                        setCustomQty(parseFloat(e.target.value) || 0)
                      }
                      className="w-full text-sm bg-white dark:bg-[#120905] border border-taupe/15 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none font-mono"
                    />
                  </div>
                  <div className="sm:col-span-3">
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                      Unit
                    </label>
                    <input
                      type="text"
                      placeholder="pcs"
                      value={customUnit}
                      onChange={(e) => setCustomUnit(e.target.value)}
                      className="w-full text-sm bg-white dark:bg-[#120905] border border-taupe/15 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none"
                    />
                  </div>
                  <div className="sm:col-span-2">
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                      Price (Ksh)
                    </label>
                    <input
                      type="number"
                      min="0"
                      value={customPrice}
                      onChange={(e) =>
                        setCustomPrice(parseInt(e.target.value) || 0)
                      }
                      className="w-full text-sm bg-white dark:bg-[#120905] border border-taupe/15 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none font-mono"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-12 gap-3"></div>

                <div className="sm:col-span-6 flex items-end">
                  <button
                    type="submit"
                    className="w-full text-sm bg-caramel hover:bg-caramel/90 text-white font-bold py-2 px-4 rounded-full flex items-center justify-center gap-1.5 cursor-pointer shadow-sm transition-all"
                  >
                    <Plus size={16} /> Add Ingredient
                  </button>
                </div>
              </form>
            </div>

            {/* Sidebar Recipes panel */}
            <div className="lg:col-span-4 space-y-6">
              {/* Saved Lists */}
              {savedLists.length > 0 && (
                <div className="bg-white dark:bg-[#1d120a] rounded-2xl p-6 shadow-xs border border-taupe/10 transition-colors duration-300">
                  <div className="flex items-center gap-2 mb-4">
                    <ClipboardList size={18} className="text-caramel" />
                    <h2 className="font-serif text-lg font-bold text-ink dark:text-parchment">
                      Saved Lists
                    </h2>
                  </div>

                  <div className="space-y-3 max-h-[300px] overflow-y-auto pr-1">
                    {savedLists.map((list) => (
                      <div
                        key={list.id}
                        className="border border-taupe/10 dark:border-stone-850/60 rounded-2xl overflow-hidden bg-gray-50/40 dark:bg-stone-900/20 p-3 flex items-center justify-between gap-2"
                      >
                        <div className="min-w-0 flex-1">
                          <h4 className="text-xs font-bold text-ink dark:text-parchment truncate">
                            {list.name}
                          </h4>
                          <p className="text-[10px] text-gray-400 mt-0.5 font-mono">
                            {list.items.length}{" "}
                            {list.items.length === 1 ? "item" : "items"}
                          </p>
                        </div>
                        <div className="flex items-center gap-1.5 shrink-0">
                          <button
                            onClick={() => handleLoadSavedList(list)}
                            className="bg-caramel/10 hover:bg-caramel text-caramel hover:text-white text-[10px] font-bold px-2.5 py-1 rounded-full transition-colors cursor-pointer"
                          >
                            Load
                          </button>
                          <button
                            onClick={() => handleDeleteSavedList(list.id)}
                            className="text-gray-400 hover:text-red-500 transition-colors p-1.5 rounded-full hover:bg-red-50 dark:hover:bg-red-950/20 cursor-pointer"
                            aria-label={`Delete ${list.name}`}
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Browse Recipes */}
              <div className="bg-white dark:bg-[#1d120a] rounded-2xl p-6 shadow-xs border border-taupe/10 transition-colors duration-300">
                <div className="flex items-center gap-2 mb-4">
                  <BookOpen size={18} className="text-caramel" />
                  <h2 className="font-serif text-lg font-bold text-ink dark:text-parchment">
                    Browse Recipes
                  </h2>
                </div>

                <div className="relative mb-4">
                  <input
                    type="text"
                    placeholder="Search recipes to import..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full text-xs pl-9 pr-4 py-2 border border-taupe/15 dark:border-stone-800 rounded-full bg-gray-50 dark:bg-stone-900 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none"
                  />
                  <Search
                    size={14}
                    className="absolute left-3.5 top-2.5 text-gray-400"
                  />
                </div>

                <div className="space-y-3 max-h-[300px] overflow-y-auto pr-1">
                  {filteredRecipes.length === 0 ? (
                    <p className="text-xs text-gray-500 dark:text-gray-400 text-center py-6">
                      No recipes found.
                    </p>
                  ) : (
                    paginatedRecipes.map((recipe) => {
                      const isExpanded = expandedRecipeId === recipe.id;
                      const hasIngredients =
                        recipe.ingredients && recipe.ingredients.length > 0;
                      return (
                        <div
                          key={recipe.id}
                          className="border border-taupe/10 dark:border-stone-850/60 rounded-xl overflow-hidden bg-gray-50/40 dark:bg-stone-900/20"
                        >
                          <button
                            onClick={() =>
                              setExpandedRecipeId(isExpanded ? null : recipe.id)
                            }
                            className="w-full flex items-center justify-between p-3 text-left hover:bg-gray-100/50 dark:hover:bg-stone-850/30 transition-colors"
                          >
                            <div className="min-w-0 pr-2">
                              <div className="flex items-center gap-1.5">
                                <h4 className="text-xs font-bold text-ink dark:text-parchment truncate">
                                  {recipe.title}
                                </h4>
                                {recipe.isCustom && (
                                  <span className="text-[8px] font-bold bg-caramel/10 text-caramel px-1.5 py-0.25 rounded-full">
                                    Saved
                                  </span>
                                )}
                              </div>
                              <p className="text-[9px] text-gray-400 capitalize mt-0.5 font-mono">
                                {recipe.dish_category.replace("_", " ")}
                              </p>
                            </div>
                            {isExpanded ? (
                              <ChevronUp size={12} className="text-gray-400" />
                            ) : (
                              <ChevronDown
                                size={12}
                                className="text-gray-400"
                              />
                            )}
                          </button>

                          {isExpanded && (
                            <div className="p-3 bg-white dark:bg-[#1d120a] border-t border-taupe/10 dark:border-stone-850 text-[11px]">
                              {hasIngredients ? (
                                <>
                                  <p className="font-bold text-[9px] uppercase tracking-wider text-gray-400 mb-2 font-mono">
                                    Ingredients:
                                  </p>
                                  <ul className="space-y-1 mb-3 pl-1">
                                    {recipe.ingredients!.map((ing, i) => (
                                      <li
                                        key={i}
                                        className="text-gray-600 dark:text-gray-300 flex justify-between"
                                      >
                                        <span>• {ing.name}</span>
                                        <span className="font-semibold text-gray-400 font-mono">
                                          {ing.quantity} {ing.unit}
                                        </span>
                                      </li>
                                    ))}
                                  </ul>
                                  <button
                                    onClick={() =>
                                      importRecipeIngredients(
                                        recipe.title,
                                        recipe.ingredients!,
                                      )
                                    }
                                    className="w-full bg-caramel/10 hover:bg-caramel text-caramel hover:text-white text-xs font-bold py-1.5 rounded-full transition-colors cursor-pointer text-center"
                                  >
                                    Add Ingredients to List
                                  </button>
                                </>
                              ) : (
                                <p className="text-gray-500 italic text-[10px]">
                                  No ingredient details available.
                                </p>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })
                  )}
                </div>

                {filteredRecipes.length > 5 && (
                  <div className="flex items-center justify-between pt-3 mt-3 border-t border-taupe/10 dark:border-stone-850 text-xs">
                    <button
                      disabled={recipePage === 1}
                      onClick={() => setRecipePage((p) => Math.max(1, p - 1))}
                      className="px-3 py-1 bg-gray-100 hover:bg-gray-200 dark:bg-stone-900 dark:hover:bg-stone-850 text-ink dark:text-parchment font-bold rounded-full disabled:opacity-50 disabled:cursor-not-allowed transition-colors cursor-pointer"
                    >
                      Prev
                    </button>
                    <span className="text-[10px] text-gray-500 dark:text-gray-400 font-mono">
                      Page {recipePage} of {totalPages}
                    </span>
                    <button
                      disabled={recipePage === totalPages}
                      onClick={() =>
                        setRecipePage((p) => Math.min(totalPages, p + 1))
                      }
                      className="px-3 py-1 bg-gray-100 hover:bg-gray-200 dark:bg-stone-900 dark:hover:bg-stone-850 text-ink dark:text-parchment font-bold rounded-full disabled:opacity-50 disabled:cursor-not-allowed transition-colors cursor-pointer"
                    >
                      Next
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            {/* Checklist Column */}
            <div className="lg:col-span-8 space-y-6">
              {/* <div className="bg-white dark:bg-[#1d120a] rounded-3xl p-6 shadow-xs border border-taupe/10 transition-colors duration-300"> */}
              <div className=" transition-colors duration-300">
                <div className="overflow-x-auto">
                  <table className="w-full border-collapse text-left">
                    <thead>
                      <tr className="border-b border-gray-100 dark:border-stone-850/80 pb-3 text-xs font-bold text-gray-400 uppercase tracking-wider">
                        <th className="pb-3 font-semibold w-8"></th>
                        <th className="pb-3 font-semibold pr-4">
                          Product Details
                        </th>
                        <th className="pb-3 font-semibold text-center w-36">
                          Quantity
                        </th>
                        <th className="pb-3 font-semibold text-right w-24">
                          Price
                        </th>
                        <th className="pb-3 font-semibold text-right w-24">
                          Amount
                        </th>
                        <th className="pb-3 font-semibold text-center w-12"></th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50 dark:divide-stone-900/60">
                      {items.map((item) => (
                        <tr
                          key={item.id}
                          className={`group transition-colors ${item.checked
                              ? "bg-gray-50/20 dark:bg-stone-900/10 text-gray-400 dark:text-stone-500"
                              : "text-ink dark:text-parchment"
                            }`}
                        >
                          {/* Checkbox */}
                          <td className="py-4.5 align-middle">
                            <button
                              onClick={() => toggleChecked(item.id)}
                              className="text-gray-400 hover:text-caramel transition-colors cursor-pointer"
                              title={
                                item.checked
                                  ? "Mark as unchecked"
                                  : "Mark as checked"
                              }
                            >
                              {item.checked ? (
                                <CheckSquare
                                  size={20}
                                  className="text-caramel fill-caramel/10"
                                />
                              ) : (
                                <Square size={20} />
                              )}
                            </button>
                          </td>

                          {/* Details */}
                          <td className="py-4.5 pr-4 align-middle">
                            <div>
                              <h3
                                className={`font-semibold text-sm transition-all ${item.checked ? "line-through opacity-60" : ""
                                  }`}
                              >
                                {item.name}
                              </h3>
                              <p className="text-[11px] text-gray-400 dark:text-gray-500 mt-0.5 font-mono">
                                Unit: {item.unit}
                              </p>
                            </div>
                          </td>

                          {/* Editable Quantity */}
                          <td className="py-4.5 text-center align-middle">
                            <div className="inline-flex items-center bg-gray-50 dark:bg-stone-900/60 rounded-full p-1 border border-taupe/15 dark:border-stone-850">
                              <button
                                onClick={() => decrementQty(item.id)}
                                className="w-7 h-7 rounded-full hover:bg-white dark:hover:bg-[#120905] text-gray-500 hover:text-ink dark:hover:text-white flex items-center justify-center transition-colors cursor-pointer font-bold shadow-xs hover:shadow-xs border border-transparent hover:border-taupe/10"
                                aria-label="Decrease quantity"
                              >
                                <Minus size={12} />
                              </button>
                              <input
                                type="number"
                                step="any"
                                min="0"
                                value={item.quantity}
                                onChange={(e) =>
                                  updateQty(
                                    item.id,
                                    parseFloat(e.target.value) || 0,
                                  )
                                }
                                className="w-12 text-center bg-transparent border-none text-xs font-bold font-mono text-ink dark:text-parchment focus:outline-none py-0 px-1 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                              />
                              <button
                                onClick={() => incrementQty(item.id)}
                                className="w-7 h-7 rounded-full hover:bg-white dark:hover:bg-[#120905] text-gray-500 hover:text-ink dark:hover:text-white flex items-center justify-center transition-colors cursor-pointer font-bold shadow-xs hover:shadow-xs border border-transparent hover:border-taupe/10"
                                aria-label="Increase quantity"
                              >
                                <Plus size={12} />
                              </button>
                            </div>
                          </td>

                          {/* Price */}
                          <td className="py-4.5 text-right font-mono text-xs font-semibold align-middle">
                            {item.price} Ksh
                          </td>

                          {/* Amount */}
                          <td className="py-4.5 text-right font-mono text-xs font-bold text-ink dark:text-parchment align-middle">
                            <span className={item.checked ? "opacity-60" : ""}>
                              {Math.round(item.price * item.quantity)} Ksh
                            </span>
                          </td>

                          {/* Action (Remove) */}
                          <td className="py-4.5 text-center align-middle">
                            <button
                              onClick={() => removeItem(item.id)}
                              className="text-gray-400 hover:text-red-500 transition-colors p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-950/20 cursor-pointer"
                              aria-label={`Remove ${item.name}`}
                            >
                              <Trash2 size={15} />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Add Custom Ingredient Inline Form */}
                <form
                  onSubmit={handleAddCustomItem}
                  className="w-full mt-6 pt-6 border-t border-gray-100 dark:border-stone-850/80 bg-gray-50/40 dark:bg-stone-900/10 p-4.5 rounded-2xl border border-dashed border-taupe/15"
                >
                  <h4 className="font-serif text-sm font-bold mb-3 text-ink dark:text-parchment flex items-center gap-1.5">
                    <Plus size={15} className="text-caramel" /> Add custom item
                  </h4>
                  <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 text-xs">
                    <div className="sm:col-span-4">
                      <input
                        type="text"
                        placeholder="Ingredient name (e.g. Vanilla extract)"
                        value={customName}
                        onChange={(e) => setCustomName(e.target.value)}
                        className="w-full bg-white dark:bg-[#120905] border border-taupe/15 dark:border-stone-850 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none"
                      />
                    </div>
                    <div className="sm:col-span-2">
                      <input
                        type="number"
                        step="any"
                        min="0.01"
                        placeholder="Qty"
                        value={customQty}
                        onChange={(e) =>
                          setCustomQty(parseFloat(e.target.value) || 0)
                        }
                        className="w-full bg-white dark:bg-[#120905] border border-taupe/15 dark:border-stone-850 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none font-mono"
                      />
                    </div>
                    <div className="sm:col-span-2">
                      <input
                        type="text"
                        placeholder="Unit (e.g. tsp)"
                        value={customUnit}
                        onChange={(e) => setCustomUnit(e.target.value)}
                        className="w-full bg-white dark:bg-[#120905] border border-taupe/15 dark:border-stone-850 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none"
                      />
                    </div>
                    <div className="sm:col-span-2">
                      <input
                        type="number"
                        min="0"
                        placeholder="Price"
                        value={customPrice}
                        onChange={(e) =>
                          setCustomPrice(parseInt(e.target.value) || 0)
                        }
                        className="w-full bg-white dark:bg-[#120905] border border-taupe/15 dark:border-stone-850 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none font-mono"
                      />
                    </div>
                    <div className="sm:col-span-2">
                      <button
                        type="submit"
                        disabled={!customName.trim()}
                        className="w-full bg-caramel hover:bg-caramel/90 disabled:bg-gray-200 dark:disabled:bg-stone-850 disabled:text-gray-400 text-white font-bold py-2 px-3 rounded-full transition-all cursor-pointer flex items-center justify-center gap-1 shadow-xs"
                      >
                        <Plus size={14} /> Add
                      </button>
                    </div>
                  </div>
                </form>
              </div>
            </div>

            {/* Sidebar Column */}
            <div className="lg:col-span-4 space-y-6">
              {/* Card 1: Shopping List Summary */}
              <div className="bg-white dark:bg-[#1d120a] rounded-2xl p-6 shadow-xs border border-taupe/10 transition-colors duration-300">
                <h2 className="font-serif text-lg font-bold mb-2 text-ink dark:text-parchment pb-2">
                  Shopping Summary
                </h2>

                <div className="space-y-3.5 text-sm">
                  <div className="flex justify-between text-gray-500 dark:text-gray-400">
                    <span>Total items</span>
                    <span className="font-bold text-ink dark:text-parchment">
                      {items.length}
                    </span>
                  </div>
                  <div className="flex justify-between text-gray-500 dark:text-gray-400">
                    <span>Checked off</span>
                    <span className="font-bold text-ink dark:text-parchment">
                      {checkedItems} / {items.length}
                    </span>
                  </div>
                  <div className="flex justify-between text-gray-500 dark:text-gray-400">
                    <span>Pending items</span>
                    <span className="font-bold text-ink dark:text-parchment">
                      {items.length - checkedItems}
                    </span>
                  </div>
                  <div className="h-px bg-gray-100 dark:bg-stone-850 my-1" />
                  <div className="flex justify-between items-baseline">
                    <span className="font-semibold text-gray-600 dark:text-gray-400">
                      Cost
                    </span>
                    <span className="font-serif text-xl font-bold text-caramel font-mono">
                      {Math.round(totalCost)}{" "}
                      <span className="text-sm text-caramel">Ksh</span>
                    </span>
                  </div>
                </div>
              </div>

              {/* Card 2: Save Current List */}
              <div className="bg-white dark:bg-[#1d120a] rounded-2xl p-6 shadow-xs border border-taupe/10 transition-colors duration-300">
                <div className="flex items-center gap-2 mb-3">
                  <Save size={16} className="text-caramel" />
                  <h2 className="font-serif text-md font-bold text-ink dark:text-parchment">
                    Save Current List
                  </h2>
                </div>
                <p className="text-[11px] text-gray-400 mb-4">
                  Save your active shopping list items to local storage.
                </p>
                <form
                  onSubmit={handleSaveCurrentList}
                  className="space-y-3 text-xs"
                >
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                      List Name
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Weekly Groceries"
                      value={listName}
                      onChange={(e) => setListName(e.target.value)}
                      className="w-full bg-gray-50 dark:bg-stone-900 border border-taupe/15 dark:border-stone-800 rounded-full px-4 py-2 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none"
                    />
                  </div>
                  <button
                    type="submit"
                    disabled={!listName.trim()}
                    className="w-full bg-caramel text-white text-xs font-bold py-2 rounded-full transition-all hover:bg-caramel/90 cursor-pointer flex items-center justify-center gap-1 shadow-xs mt-2 disabled:bg-gray-200 dark:disabled:bg-stone-850 disabled:text-gray-400"
                  >
                    Save List
                  </button>
                </form>
              </div>

              {/* Saved Lists */}
              {savedLists.length > 0 && (
                <div className="bg-white dark:bg-[#1d120a] rounded-2xl p-6 shadow-xs border border-taupe/10 transition-colors duration-300">
                  <div className="flex items-center gap-2 mb-4">
                    <ClipboardList size={18} className="text-caramel" />
                    <h2 className="font-serif text-lg font-bold text-ink dark:text-parchment">
                      Saved Lists
                    </h2>
                  </div>

                  <div className="space-y-3 max-h-[300px] overflow-y-auto pr-1">
                    {savedLists.map((list) => (
                      <div
                        key={list.id}
                        className="border border-taupe/10 dark:border-stone-850/60 rounded-2xl overflow-hidden bg-gray-50/40 dark:bg-stone-900/20 p-3 flex items-center justify-between gap-2"
                      >
                        <div className="min-w-0 flex-1">
                          <h4 className="text-xs font-bold text-ink dark:text-parchment truncate">
                            {list.name}
                          </h4>
                          <p className="text-[10px] text-gray-400 mt-0.5 font-mono">
                            {list.items.length}{" "}
                            {list.items.length === 1 ? "item" : "items"}
                          </p>
                        </div>
                        <div className="flex items-center gap-1.5 shrink-0">
                          <button
                            onClick={() => handleLoadSavedList(list)}
                            className="bg-caramel/10 hover:bg-caramel text-caramel hover:text-white text-[10px] font-bold px-2.5 py-1 rounded-full transition-colors cursor-pointer"
                          >
                            Load
                          </button>
                          <button
                            onClick={() => handleDeleteSavedList(list.id)}
                            className="text-gray-400 hover:text-red-500 transition-colors p-1.5 rounded-full hover:bg-red-50 dark:hover:bg-red-950/20 cursor-pointer"
                            aria-label={`Delete ${list.name}`}
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Browse Recipes */}
              <div className="bg-white dark:bg-[#1d120a] rounded-2xl p-6 shadow-xs border border-taupe/10 transition-colors duration-300">
                <div className="flex items-center gap-2 mb-4">
                  <BookOpen size={18} className="text-caramel" />
                  <h2 className="font-serif text-lg font-bold text-ink dark:text-parchment">
                    Browse Recipes
                  </h2>
                </div>

                <div className="relative mb-4">
                  <input
                    type="text"
                    placeholder="Search recipes to import..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full text-xs pl-9 pr-4 py-2 border border-taupe/15 dark:border-stone-800 rounded-full bg-gray-50 dark:bg-stone-900 text-ink dark:text-parchment focus:ring-1 focus:ring-caramel focus:outline-none"
                  />
                  <Search
                    size={14}
                    className="absolute left-3.5 top-2.5 text-gray-400"
                  />
                </div>

                <div className="space-y-3 max-h-[300px] overflow-y-auto pr-1">
                  {filteredRecipes.length === 0 ? (
                    <p className="text-xs text-gray-500 dark:text-gray-400 text-center py-6">
                      No recipes found.
                    </p>
                  ) : (
                    paginatedRecipes.map((recipe) => {
                      const isExpanded = expandedRecipeId === recipe.id;
                      const hasIngredients =
                        recipe.ingredients && recipe.ingredients.length > 0;
                      return (
                        <div
                          key={recipe.id}
                          className="border border-taupe/10 dark:border-stone-850/60 rounded-xl overflow-hidden bg-gray-50/40 dark:bg-stone-900/20"
                        >
                          <button
                            onClick={() =>
                              setExpandedRecipeId(isExpanded ? null : recipe.id)
                            }
                            className="w-full flex items-center justify-between p-3 text-left hover:bg-gray-100/50 dark:hover:bg-stone-850/30 transition-colors"
                          >
                            <div className="min-w-0 pr-2">
                              <div className="flex items-center gap-1.5">
                                <h4 className="text-xs font-bold text-ink dark:text-parchment truncate">
                                  {recipe.title}
                                </h4>
                                {recipe.isCustom && (
                                  <span className="text-[8px] font-bold bg-caramel/10 text-caramel px-1.5 py-0.25 rounded-full">
                                    Saved
                                  </span>
                                )}
                              </div>
                              <p className="text-[9px] text-gray-400 capitalize mt-0.5 font-mono">
                                {recipe.dish_category.replace("_", " ")}
                              </p>
                            </div>
                            {isExpanded ? (
                              <ChevronUp size={12} className="text-gray-400" />
                            ) : (
                              <ChevronDown
                                size={12}
                                className="text-gray-400"
                              />
                            )}
                          </button>

                          {isExpanded && (
                            <div className="p-3 bg-white dark:bg-[#1d120a] border-t border-taupe/10 dark:border-stone-850 text-[11px]">
                              {hasIngredients ? (
                                <>
                                  <p className="font-bold text-[9px] uppercase tracking-wider text-gray-400 mb-2 font-mono">
                                    Ingredients:
                                  </p>
                                  <ul className="space-y-1 mb-3 pl-1">
                                    {recipe.ingredients!.map((ing, i) => (
                                      <li
                                        key={i}
                                        className="text-gray-600 dark:text-gray-300 flex justify-between"
                                      >
                                        <span>• {ing.name}</span>
                                        <span className="font-semibold text-gray-400 font-mono">
                                          {ing.quantity} {ing.unit}
                                        </span>
                                      </li>
                                    ))}
                                  </ul>
                                  <button
                                    onClick={() =>
                                      importRecipeIngredients(
                                        recipe.title,
                                        recipe.ingredients!,
                                      )
                                    }
                                    className="w-full bg-caramel/10 hover:bg-caramel text-caramel hover:text-white text-xs font-bold py-1.5 rounded-full transition-colors cursor-pointer text-center"
                                  >
                                    Add Ingredients to List
                                  </button>
                                </>
                              ) : (
                                <p className="text-gray-500 italic text-[10px]">
                                  No ingredient details available.
                                </p>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })
                  )}
                </div>

                {filteredRecipes.length > 5 && (
                  <div className="flex items-center justify-between pt-3 mt-3 border-t border-taupe/10 dark:border-stone-850 text-xs">
                    <button
                      disabled={recipePage === 1}
                      onClick={() => setRecipePage((p) => Math.max(1, p - 1))}
                      className="px-3 py-1 bg-gray-100 hover:bg-gray-200 dark:bg-stone-900 dark:hover:bg-stone-850 text-ink dark:text-parchment font-bold rounded-full disabled:opacity-50 disabled:cursor-not-allowed transition-colors cursor-pointer"
                    >
                      Prev
                    </button>
                    <span className="text-[10px] text-gray-500 dark:text-gray-400 font-mono">
                      Page {recipePage} of {totalPages}
                    </span>
                    <button
                      disabled={recipePage === totalPages}
                      onClick={() =>
                        setRecipePage((p) => Math.min(totalPages, p + 1))
                      }
                      className="px-3 py-1 bg-gray-100 hover:bg-gray-200 dark:bg-stone-900 dark:hover:bg-stone-850 text-ink dark:text-parchment font-bold rounded-full disabled:opacity-50 disabled:cursor-not-allowed transition-colors cursor-pointer"
                    >
                      Next
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
