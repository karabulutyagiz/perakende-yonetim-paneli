import Image from "next/image";
import { Mail, Lock, Eye } from "lucide-react";

/**
 * iPhone-shaped frame containing a faithful HTML render of the ParaSende
 * mobile login screen. Used in the marketing hero so visitors immediately
 * recognize the actual login UI.
 */
export function PhoneLoginMockup({ className }: { className?: string }) {
  return (
    <div className={className}>
      <div className="relative mx-auto aspect-[9/19.5] w-full max-w-[320px]">
        {/* Outer bezel */}
        <div className="absolute inset-0 rounded-[2.6rem] bg-neutral-900 p-[10px] shadow-[0_30px_60px_-20px_rgba(0,0,0,0.45),0_0_0_1px_rgba(255,255,255,0.04)_inset]">
          {/* Inner screen */}
          <div className="relative h-full w-full overflow-hidden rounded-[2.1rem] bg-white">
            {/* Dynamic island */}
            <div className="pointer-events-none absolute left-1/2 top-2 z-20 h-[22px] w-[88px] -translate-x-1/2 rounded-full bg-neutral-900" />

            {/* Status bar */}
            <div className="flex h-9 items-center justify-between px-6 pt-1.5 text-[11px] font-semibold text-neutral-900">
              <span>9:41</span>
              <div className="flex items-center gap-1">
                <span className="inline-block h-2 w-3 rounded-[1px] bg-neutral-900" />
                <span className="inline-block h-2 w-3 rounded-[1px] bg-neutral-900" />
                <span className="inline-block h-2 w-4 rounded-[2px] border border-neutral-900" />
              </div>
            </div>

            {/* Login content */}
            <div className="flex h-[calc(100%-2.25rem)] flex-col items-stretch px-6 pb-6 pt-6">
              <div className="flex flex-col items-center">
                <Image
                  src="/app-icon.png"
                  alt=""
                  width={72}
                  height={72}
                  className="h-[64px] w-[64px] rounded-2xl object-cover"
                />
                <p className="mt-3 text-[17px] font-bold text-neutral-900">
                  ParaSende
                </p>
                <p className="mt-0.5 text-[11px] text-neutral-500">
                  Stok ve sipariş yönetimi
                </p>
              </div>

              <div className="mt-7 space-y-3">
                <Field
                  icon={<Mail className="h-3.5 w-3.5" />}
                  label="E-posta"
                  value="ornek@isletme.com"
                />
                <Field
                  icon={<Lock className="h-3.5 w-3.5" />}
                  label="Parola"
                  value="••••••••"
                  trailing={<Eye className="h-3.5 w-3.5 text-neutral-400" />}
                />
              </div>

              <button
                type="button"
                aria-hidden
                tabIndex={-1}
                className="mt-5 inline-flex h-10 items-center justify-center rounded-xl bg-emerald-600 text-[12px] font-semibold text-white shadow-[0_4px_12px_-4px_rgba(5,150,105,0.6)]"
              >
                Giriş yap
              </button>
              <button
                type="button"
                aria-hidden
                tabIndex={-1}
                className="mt-2 text-center text-[10.5px] font-medium text-emerald-700"
              >
                Hesabın yok mu? · İşletme hesabı aç
              </button>

              <div className="mt-auto pt-4 text-center text-[9px] uppercase tracking-[0.18em] text-neutral-400">
                toptanperakende.online
              </div>
            </div>
          </div>
        </div>

        {/* Side buttons */}
        <span
          aria-hidden
          className="absolute -left-[3px] top-[110px] h-[34px] w-[3px] rounded-l-sm bg-neutral-800"
        />
        <span
          aria-hidden
          className="absolute -left-[3px] top-[160px] h-[58px] w-[3px] rounded-l-sm bg-neutral-800"
        />
        <span
          aria-hidden
          className="absolute -left-[3px] top-[230px] h-[58px] w-[3px] rounded-l-sm bg-neutral-800"
        />
        <span
          aria-hidden
          className="absolute -right-[3px] top-[180px] h-[88px] w-[3px] rounded-r-sm bg-neutral-800"
        />
      </div>
    </div>
  );
}

function Field({
  icon,
  label,
  value,
  trailing,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  trailing?: React.ReactNode;
}) {
  return (
    <div className="rounded-xl border border-neutral-200 bg-white px-3 py-2 shadow-[0_1px_2px_rgba(15,23,42,0.04)]">
      <p className="text-[9px] font-medium uppercase tracking-[0.08em] text-emerald-700">
        {label}
      </p>
      <div className="mt-0.5 flex items-center gap-2">
        <span className="text-neutral-500">{icon}</span>
        <span className="flex-1 text-[12px] text-neutral-700">{value}</span>
        {trailing}
      </div>
    </div>
  );
}
