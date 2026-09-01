import { ChevronLeft, ChevronRight, X } from "lucide-react";
import { useCallback, useEffect, useState } from "react";

export type StepImage = {
  src: string;
  alt?: string;
};

interface StepImageCarouselProps {
  images: StepImage[];
  stepTitle: string;
}

export function StepImageCarousel({
  images,
  stepTitle,
}: StepImageCarouselProps) {
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null);
  const hasMultipleImages = images.length > 1;

  const closeLightbox = useCallback(() => {
    setSelectedIndex(null);
  }, []);

  const showPrevious = useCallback(() => {
    setSelectedIndex((current) => {
      if (current === null) return null;
      return current === 0 ? images.length - 1 : current - 1;
    });
  }, [images.length]);

  const showNext = useCallback(() => {
    setSelectedIndex((current) => {
      if (current === null) return null;
      return current === images.length - 1 ? 0 : current + 1;
    });
  }, [images.length]);

  useEffect(() => {
    if (selectedIndex === null) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") closeLightbox();
      if (event.key === "ArrowLeft") showPrevious();
      if (event.key === "ArrowRight") showNext();
    };

    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", onKeyDown);

    return () => {
      document.body.style.overflow = "";
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [selectedIndex, closeLightbox, showPrevious, showNext]);

  if (images.length === 0) return null;

  const selectedImage =
    selectedIndex !== null ? images[selectedIndex] : null;

  return (
    <>
      <div className="mt-4 w-full overflow-hidden rounded-xl">
        <div
          className="flex gap-3 overflow-x-auto p-3 scroll-smooth"
          aria-label={`${stepTitle} images`}
        >
          {images.map((image, index) => (
            <button
              key={`${image.src}-${index}`}
              type="button"
              onClick={() => setSelectedIndex(index)}
              aria-label={`View ${image.alt ?? `${stepTitle} image ${index + 1}`}`}
              className=" border border-gray-100 hover:cursor-pointer aspect-square h-28 w-28 shrink-0 overflow-hidden rounded-lg bg-gray-50 transition-transform duration-150 hover:scale-[1.02] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-caramel sm:h-40 sm:w-40"
            >
              <img
                src={image.src}
                alt={image.alt ?? `${stepTitle} - image ${index + 1}`}
                className="h-full w-full object-contain"
              />
            </button>
          ))}
        </div>
      </div>

      {selectedImage && selectedIndex !== null && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/80 p-4 backdrop-blur-xs">
          <button
            type="button"
            aria-label="Close image preview"
            onClick={closeLightbox}
            className="absolute inset-0 cursor-default"
          />

          <div
            role="dialog"
            aria-modal="true"
            aria-label={`${stepTitle} image preview`}
            className="relative z-10 flex max-h-[90vh] max-w-[min(92vw,960px)] flex-col items-center"
          >
            <button
              type="button"
              onClick={closeLightbox}
              aria-label="Close"
              className="absolute -top-12 right-0 flex h-10 w-10 items-center justify-center rounded-full border border-white/20 bg-black/40 text-white transition-colors hover:bg-black/60 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
            >
              <X size={20} />
            </button>

            <img
              src={selectedImage.src}
              alt={
                selectedImage.alt ??
                `${stepTitle} - image ${selectedIndex + 1}`
              }
              className="max-h-[85vh] max-w-full rounded-xl object-contain shadow-2xl"
            />

            {hasMultipleImages && (
              <>
                <button
                  type="button"
                  onClick={showPrevious}
                  aria-label="Previous image"
                  className="absolute left-0 top-1/2 flex h-10 w-10 -translate-x-3 -translate-y-1/2 items-center justify-center rounded-full border border-white/20 bg-black/40 text-white transition-colors hover:bg-black/60 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white sm:-translate-x-14"
                >
                  <ChevronLeft size={20} />
                </button>

                <button
                  type="button"
                  onClick={showNext}
                  aria-label="Next image"
                  className="absolute right-0 top-1/2 flex h-10 w-10 -translate-y-1/2 translate-x-3 items-center justify-center rounded-full border border-white/20 bg-black/40 text-white transition-colors hover:bg-black/60 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white sm:translate-x-14"
                >
                  <ChevronRight size={20} />
                </button>

                <p className="mt-4 text-sm font-medium text-white/80">
                  {selectedIndex + 1} / {images.length}
                </p>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}
