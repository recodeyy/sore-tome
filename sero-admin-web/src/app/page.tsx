import { getSessionUser } from "@/lib/session";
import Landing from "@/components/marketing/Landing";

export default function Home() {
  const user = getSessionUser();
  // The landing page always shows at `/`. If the visitor is already signed in,
  // the CTA/Sign-in buttons take them straight to their portal dashboard;
  // otherwise to the login screen.
  const ctaHref = user
    ? user.portal === "super-admin"
      ? "/super-admin/dashboard"
      : "/dashboard"
    : "/login";
  return <Landing ctaHref={ctaHref} signedIn={!!user} />;
}
