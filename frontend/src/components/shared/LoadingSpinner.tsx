export default function LoadingSpinner() {
  return (
    <div className="flex items-center justify-center p-[clamp(16px,2vh,40px)]">
      <div className="w-[clamp(24px,2vw,40px)] h-[clamp(24px,2vw,40px)] border-[3px] border-white/10 border-t-accent rounded-full animate-spin" />
    </div>
  )
}
