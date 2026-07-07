import { redirect } from "next/navigation";
import { getSessionUser } from "@/lib/session";

export default function Home() {
  const user = getSessionUser();
  if (!user) redirect("/login");
  redirect(user.portal === "super-admin" ? "/super-admin/dashboard" : "/dashboard");
}
