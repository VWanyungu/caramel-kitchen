import { SOFIA_VIDEOS, type SofiaVideo } from "../data/sofiaVideosData";

const SAVED_VIDEOS_KEY = "caramel_saved_sofia_videos";
const CUSTOM_EVENT_NAME = "caramel_saved_videos_updated";

export const getSavedVideoIds = (): string[] => {
  try {
    const raw = localStorage.getItem(SAVED_VIDEOS_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    console.error("Error reading saved videos from localStorage", e);
    return [];
  }
};

export const getSavedVideos = (): SofiaVideo[] => {
  const savedIds = new Set(getSavedVideoIds());
  return SOFIA_VIDEOS.filter((video) => savedIds.has(video.id));
};

export const isVideoSaved = (videoId: string): boolean => {
  const savedIds = getSavedVideoIds();
  return savedIds.includes(videoId);
};

export const toggleSaveVideo = (videoId: string): boolean => {
  try {
    const current = getSavedVideoIds();
    let updated: string[];
    let nowSaved = false;

    if (current.includes(videoId)) {
      updated = current.filter((id) => id !== videoId);
      nowSaved = false;
    } else {
      updated = [...current, videoId];
      nowSaved = true;
    }

    localStorage.setItem(SAVED_VIDEOS_KEY, JSON.stringify(updated));

    // Dispatch custom event for real-time reactivity in app
    window.dispatchEvent(new Event(CUSTOM_EVENT_NAME));

    return nowSaved;
  } catch (e) {
    console.error("Error updating saved videos in localStorage", e);
    return false;
  }
};

export const subscribeToSavedVideos = (callback: () => void): (() => void) => {
  const handleStorageChange = (e: StorageEvent) => {
    if (e.key === SAVED_VIDEOS_KEY) {
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
