import { useState, useEffect } from "react";
import { Check, Sparkles, ChevronLeft, ChevronRight } from "lucide-react";

const SLIDES = [
  {
    src: "/hero.jpg",
    title: "Artisanal Caramel Delights",
    subtitle: "Crafted with passion & finest ingredients",
  },
  {
    src: "/hero-2.jpg",
    title: "Fresh Seasonal Pastas",
    subtitle: "Simple, delicious, comforting recipes",
  },
  {
    src: "/hero-3.jpg",
    title: "Nutritious & Vibrant Bowls",
    subtitle: "Fuel your day with balanced meals",
  },
];

const RECIPE_TYPES = [
  // "vegetarian recipes",
  // "gluten-free recipes",
  "quick & easy recipes",
  "high protein recipes",
  // "high fibre recipes",
  // "healthy recipes",
  // "gourmet recipes",
];

export function Hero() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [isAutoPlaying, setIsAutoPlaying] = useState(true);
  const [recipeTypeIndex, setRecipeTypeIndex] = useState(0);

  const prevSlide = () => {
    setCurrentSlide((prev) => (prev === 0 ? SLIDES.length - 1 : prev - 1));
  };

  const nextSlide = () => {
    setCurrentSlide((prev) => (prev === SLIDES.length - 1 ? 0 : prev + 1));
  };

  useEffect(() => {
    if (!isAutoPlaying) return;
    const interval = setInterval(() => {
      nextSlide();
    }, 5000);
    return () => clearInterval(interval);
  }, [isAutoPlaying, currentSlide]);

  useEffect(() => {
    const timer = setInterval(() => {
      setRecipeTypeIndex((prev) => (prev + 1) % RECIPE_TYPES.length);
    }, 2600);
    return () => clearInterval(timer);
  }, []);

  return (
    <section className="py-12 px-8 lg:px-24 grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
      <div className="flex flex-col justify-center items-start">
        {/* <div className="rounded-full bg-gray-100 flex items-center">
          <button className="cursor-pointer rounded-full px-4 py-1.5 bg-white shadow-xs border border-gray-200 text-xs font-semibold tracking-wider uppercase text-ink">
            discover
          </button>
          <button className="cursor-pointer rounded-full px-4 py-1.5 text-xs text-gray-500 hover:text-ink font-semibold tracking-wider uppercase transition-colors">
            create
          </button>
        </div> */}

        <h1 className="font-serif text-4xl sm:text-5xl lg:text-6xl text-ink font-medium tracking-tighter leading-tight">
          All the{" "}
          <span className="inline-flex h-[1.25em] overflow-hidden align-bottom -mb-1">
            <span
              className="flex flex-col transition-transform duration-700 ease-[cubic-bezier(0.25,1,0.5,1)]"
              style={{
                transform: `translateY(-${(recipeTypeIndex * 100) + 10}%)`,
              }}
            >
              {RECIPE_TYPES.map((type) => (
                <span
                  key={type}
                  className="font-display font-bold italic text-caramel whitespace-nowrap h-[1.25em] flex items-center"
                >
                  {type}
                </span>
              ))}
            </span>
          </span>
          {" "}
          you need, organized for you in a simple and delicious way
        </h1>

        <div className="mt-6 flex flex-col items-start gap-3">
          <div className="flex gap-3 items-center justify-start text-sm text-ink/80">
            <div className="p-1 bg-caramel/20 rounded-full flex items-center justify-center shrink-0">
              <Check size={14} className="text-caramel font-bold" />
            </div>
            <span>Generate your meal plans and achieve your health goals</span>
          </div>
          <div className="flex gap-3 items-center justify-start text-sm text-ink/80">
            <div className="p-1 bg-caramel/20 rounded-full flex items-center justify-center shrink-0">
              <Check size={14} className="text-caramel font-bold" />
            </div>
            <span>Save your favorite recipes and custom grocery lists</span>
          </div>
          <div className="flex gap-3 items-center justify-start text-sm text-ink/80">
            <div className="p-1 bg-caramel/20 rounded-full flex items-center justify-center shrink-0">
              <Check size={14} className="text-caramel font-bold" />
            </div>
            <span>Explore step-by-step cooking guides from expert chefs</span>
          </div>
        </div>

        <button
          className="capitalize mt-8 cursor-pointer font-semibold flex items-center gap-2 bg-caramel hover:bg-caramel/90 text-white rounded-full px-7 py-3.5 text-sm transition-all shadow-md hover:shadow-lg active:scale-95"
        >
          <Sparkles size={18} /> Create your first meal plan
        </button>
      </div>

      {/* Image Slider */}
      <div
        className="relative w-full h-full rounded-2xl overflow-hidden shadow-xl border border-gray-200/80 group"
        onMouseEnter={() => setIsAutoPlaying(false)}
        onMouseLeave={() => setIsAutoPlaying(true)}
      >
        {SLIDES.map((slide, index) => (
          <div
            key={slide.src}
            className={`absolute inset-0 transition-opacity duration-700 ease-in-out ${index === currentSlide ? "opacity-100 z-10" : "opacity-0 z-0 pointer-events-none"
              }`}
          >
            <img
              src={slide.src}
              alt={slide.title}
              className="w-full h-full object-cover"
              style={{ height: "100%" }}
            />
            {/* Gradient Overlay & Caption */}
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent pointer-events-none" />
            <div className="absolute bottom-6 left-6 right-20 text-white z-20">
              <h3 className="font-serif text-xl font-bold">{slide.title}</h3>
              <p className="text-xs text-white/80 mt-1 font-sans">{slide.subtitle}</p>
            </div>
          </div>
        ))}

        {/* Control Buttons - Previous & Next */}
        <button
          onClick={prevSlide}
          aria-label="Previous slide"
          className="absolute left-4 top-1/2 -translate-y-1/2 z-28 p-2.5 rounded-full bg-white/30 backdrop-blur-md text-white hover:bg-white/80 hover:text-ink transition-all cursor-pointer opacity-90 group-hover:opacity-100 hover:scale-110"
        >
          <ChevronLeft size={22} />
        </button>
        <button
          onClick={nextSlide}
          aria-label="Next slide"
          className="absolute right-4 top-1/2 -translate-y-1/2 z-28 p-2.5 rounded-full bg-white/30 backdrop-blur-md text-white hover:bg-white/80 hover:text-ink transition-all cursor-pointer opacity-90 group-hover:opacity-100 hover:scale-110"
        >
          <ChevronRight size={22} />
        </button>

        {/* Slide Indicators / Dots */}
        <div className="absolute bottom-6 right-6 z-28 flex items-center gap-2 bg-black/40 backdrop-blur-md px-3 py-1.5 rounded-full">
          {SLIDES.map((_, index) => (
            <button
              key={index}
              onClick={() => setCurrentSlide(index)}
              aria-label={`Go to slide ${index + 1}`}
              className={`h-2 rounded-full transition-all cursor-pointer ${index === currentSlide ? "w-6 bg-butter" : "w-2 bg-white/50 hover:bg-white/80"
                }`}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

