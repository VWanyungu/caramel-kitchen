const SAVED_COLLECTIONS_KEY = "caramel_saved_collections";
const CUSTOM_EVENT_NAME = "caramel_saved_collections_updated";

export const getSavedCollectionIds = (): string[] => {
  try {
    const raw = localStorage.getItem(SAVED_COLLECTIONS_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    console.error("Error reading saved collections from localStorage", e);
    return [];
  }
};

export const isCollectionSaved = (collectionId: string): boolean => {
  return getSavedCollectionIds().includes(collectionId);
};

export const toggleSaveCollection = (collectionId: string): boolean => {
  try {
    const current = getSavedCollectionIds();
    let updated: string[];
    let nowSaved = false;

    if (current.includes(collectionId)) {
      updated = current.filter((id) => id !== collectionId);
      nowSaved = false;
    } else {
      updated = [...current, collectionId];
      nowSaved = true;
    }

    localStorage.setItem(SAVED_COLLECTIONS_KEY, JSON.stringify(updated));
    window.dispatchEvent(new Event(CUSTOM_EVENT_NAME));
    return nowSaved;
  } catch (e) {
    console.error("Error updating saved collections in localStorage", e);
    return false;
  }
};

export const subscribeToSavedCollections = (callback: () => void): (() => void) => {
  const handleStorageChange = (e: StorageEvent) => {
    if (e.key === SAVED_COLLECTIONS_KEY) {
      callback();
    }
  };

  const handleCustomEvent = () => {
    callback();
  };

  window.addEventListener("storage", handleStorageChange);
  window.addEventListener(CUSTOM_EVENT_NAME, handleCustomEvent);

  return () => {
    window.removeEventListener("storage", handleStorageChange);
    window.removeEventListener(CUSTOM_EVENT_NAME, handleCustomEvent);
  };
};
