"use client";
import { useMemo, useState } from "react";
import { Plus, Download, Send, IndianRupee } from "lucide-react";
import { useApi, useApiMutation, num } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { PageHeader, Card, StatusChip, Modal } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatMoneyMinor, formatDate } from "@/lib/format";
import { exportCsv, exportPdf, exportReceipt } from "@/lib/export";

type Invoice = {
  id: string;
  number: string;
  period: string | null;
  status: string;
  member_id: string | null;
  total_minor: string | number;
  tax_minor: string | number;
  due_date: string | null;
};
type Member = { id: string; name: string; unit_id: string | null };

const STATUS_TONE: Record<string, "green" | "amber" | "slate" | "red"> = {
  paid: "green",
  published: "blue" as any,
  draft: "slate",
  overdue: "red",
  partial: "amber",
};

export default function BillingPage() {
  const { push } = useToast();
  const invoicesQ = useApi<{ invoices: Invoice[] }>(["finance", "invoices"], "/finance/invoices");
  const membersQ = useApi<{ members: Member[] }>(["members"], "/members-v2");
  const createInv = useApiMutation("post", [["finance", "invoices"]]);
  const publishInv = useApiMutation("post", [["finance", "invoices"]]);
  const recordPay = useApiMutation("post", [["finance", "invoices"], ["finance", "dues"]]);

  const [showCreate, setShowCreate] = useState(false);
  const [payFor, setPayFor] = useState<Invoice | null>(null);

  const invoices = invoicesQ.data?.invoices || [];
  const members = membersQ.data?.members || [];
  const memberName = (id: string | null) =>
    members.find((m) => m.id === id)?.name || (id ? id.slice(0, 8) : "—");

  const totals = useMemo(() => {
    const total = invoices.reduce((a, i) => a + num(i.total_minor), 0);
    const paid = invoices.filter((i) => i.status === "paid").reduce((a, i) => a + num(i.total_minor), 0);
    const outstanding = total - paid;
    const rate = total > 0 ? Math.round((paid / total) * 100) : 0;
    return { total, paid, outstanding, rate, count: invoices.length };
  }, [invoices]);

  function downloadReceipt(inv: Invoice) {
    exportReceipt({
      number: inv.number,
      memberName: memberName(inv.member_id),
      period: inv.period,
      status: inv.status,
      totalMinor: num(inv.total_minor),
      taxMinor: num(inv.tax_minor),
      dueDate: inv.due_date ? formatDate(inv.due_date) : null,
      societyName: "Hubtown Sunkist",
    });
    push("success", `Receipt ${inv.number} downloaded`);
  }

  function doExportCsv() {
    exportCsv(
      `invoices-${new Date().toISOString().slice(0, 10)}`,
      [
        { header: "Invoice", accessor: (r: Invoice) => r.number },
        { header: "Member", accessor: (r: Invoice) => memberName(r.member_id) },
        { header: "Period", accessor: (r: Invoice) => r.period || "" },
        { header: "Status", accessor: (r: Invoice) => r.status },
        { header: "Total (INR)", accessor: (r: Invoice) => (num(r.total_minor) / 100).toFixed(2) },
        { header: "Due Date", accessor: (r: Invoice) => (r.due_date ? formatDate(r.due_date) : "") },
      ],
      invoices
    );
  }
  function doExportPdf() {
    exportPdf(
      `invoices-${new Date().toISOString().slice(0, 10)}`,
      "Billing — Invoices",
      [
        { header: "Invoice", accessor: (r: Invoice) => r.number },
        { header: "Member", accessor: (r: Invoice) => memberName(r.member_id) },
        { header: "Period", accessor: (r: Invoice) => r.period || "" },
        { header: "Status", accessor: (r: Invoice) => r.status },
        { header: "Total", accessor: (r: Invoice) => formatMoneyMinor(num(r.total_minor)) },
      ],
      invoices,
      "Hubtown Sunkist · live data"
    );
  }

  return (
    <div>
      <PageHeader
        title="Billing"
        subtitle="Maintenance invoices, GST, and payment status — live"
        actions={
          <>
            <button className="btn-outline" onClick={doExportCsv} disabled={!invoices.length}>
              <Download className="h-4 w-4" /> CSV
            </button>
            <button className="btn-outline" onClick={doExportPdf} disabled={!invoices.length}>
              <Download className="h-4 w-4" /> PDF
            </button>
            <button className="btn-primary" onClick={() => setShowCreate(true)}>
              <Plus className="h-4 w-4" /> New Bill
            </button>
          </>
        }
      />

      <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Card className="p-4">
          <p className="text-xs uppercase text-slate-500">Invoices</p>
          <p className="mt-1 text-2xl font-semibold">{totals.count}</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs uppercase text-slate-500">Total Invoiced</p>
          <p className="mt-1 text-2xl font-semibold">{formatMoneyMinor(totals.total)}</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs uppercase text-slate-500">Collected</p>
          <p className="mt-1 text-2xl font-semibold text-brand-600">{formatMoneyMinor(totals.paid)}</p>
          <p className="mt-0.5 text-xs text-slate-400">{totals.rate}% collection rate</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs uppercase text-slate-500">Outstanding</p>
          <p className={`mt-1 text-2xl font-semibold ${totals.outstanding > 0 ? "text-red-600" : "text-slate-900"}`}>
            {formatMoneyMinor(totals.outstanding)}
          </p>
        </Card>
      </div>

      {invoicesQ.isLoading ? (
        <LoadingState />
      ) : invoicesQ.isError ? (
        <ErrorState onRetry={() => invoicesQ.refetch()} />
      ) : invoices.length === 0 ? (
        <EmptyState title="No invoices yet" hint="Create your first maintenance bill." />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Invoice</th>
                <th>Member</th>
                <th>Period</th>
                <th>Status</th>
                <th className="text-right">Total</th>
                <th>Due</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {invoices.map((inv) => (
                <tr key={inv.id}>
                  <td className="font-medium text-slate-900">{inv.number}</td>
                  <td>{memberName(inv.member_id)}</td>
                  <td>{inv.period || "—"}</td>
                  <td>
                    <StatusChip tone={STATUS_TONE[inv.status] || "slate"}>{inv.status}</StatusChip>
                  </td>
                  <td className="text-right font-medium">{formatMoneyMinor(num(inv.total_minor))}</td>
                  <td>{inv.due_date ? formatDate(inv.due_date) : "—"}</td>
                  <td className="text-right">
                    <div className="flex justify-end gap-1">
                      {inv.status === "draft" && (
                        <button
                          className="btn-ghost h-8 px-2 text-xs"
                          onClick={() =>
                            publishInv.mutate(
                              { path: `/finance/invoices/${inv.id}/publish` },
                              {
                                onSuccess: () => push("success", `${inv.number} published`),
                                onError: (e) => push("error", e.message),
                              }
                            )
                          }
                        >
                          <Send className="h-3.5 w-3.5" /> Publish
                        </button>
                      )}
                      {inv.status !== "paid" && (
                        <button
                          className="btn-ghost h-8 px-2 text-xs"
                          onClick={() => setPayFor(inv)}
                        >
                          <IndianRupee className="h-3.5 w-3.5" /> Record
                        </button>
                      )}
                      <button
                        className="btn-ghost h-8 px-2 text-xs"
                        title={inv.status === "paid" ? "Download receipt" : "Download invoice"}
                        onClick={() => downloadReceipt(inv)}
                      >
                        <Download className="h-3.5 w-3.5" />
                        {inv.status === "paid" ? "Receipt" : "Invoice"}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {showCreate && (
        <CreateBillModal
          members={members}
          onClose={() => setShowCreate(false)}
          onSubmit={(body) =>
            createInv.mutate(
              { path: "/finance/invoices", body },
              {
                onSuccess: () => {
                  push("success", "Invoice created");
                  setShowCreate(false);
                },
                onError: (e) => push("error", e.message),
              }
            )
          }
          submitting={createInv.isPending}
        />
      )}

      {payFor && (
        <RecordPaymentModal
          invoice={payFor}
          onClose={() => setPayFor(null)}
          onSubmit={(amountMinor) =>
            recordPay.mutate(
              {
                path: "/finance/payments",
                body: {
                  idempotencyKey: `web-${payFor.id}-${Date.now()}`,
                  invoiceId: payFor.id,
                  amountMinor,
                  provider: "manual",
                },
              },
              {
                onSuccess: () => {
                  push("success", "Payment recorded");
                  setPayFor(null);
                },
                onError: (e) => push("error", e.message),
              }
            )
          }
          submitting={recordPay.isPending}
        />
      )}
    </div>
  );
}

function CreateBillModal({
  members,
  onClose,
  onSubmit,
  submitting,
}: {
  members: Member[];
  onClose: () => void;
  onSubmit: (body: any) => void;
  submitting: boolean;
}) {
  const [number, setNumber] = useState(`INV-${Date.now().toString().slice(-6)}`);
  const [memberId, setMemberId] = useState(members[0]?.id || "");
  const [period, setPeriod] = useState(new Date().toISOString().slice(0, 7));
  const [dueDate, setDueDate] = useState("");
  const [desc, setDesc] = useState("Monthly Maintenance");
  const [amount, setAmount] = useState("4500");
  const [tax, setTax] = useState("810");

  return (
    <Modal
      open
      onClose={onClose}
      title="Create Maintenance Bill"
      footer={
        <>
          <button className="btn-outline" onClick={onClose}>Cancel</button>
          <button
            className="btn-primary"
            disabled={submitting}
            onClick={() =>
              onSubmit({
                number,
                memberId: memberId || undefined,
                period,
                dueDate: dueDate || undefined,
                lines: [
                  {
                    description: desc,
                    component: "maintenance",
                    quantity: 1,
                    unitPriceMinor: Math.round(Number(amount) * 100),
                    taxMinor: Math.round(Number(tax) * 100),
                  },
                ],
              })
            }
          >
            Create
          </button>
        </>
      }
    >
      <div className="grid grid-cols-2 gap-3">
        <label className="text-sm">
          <span className="mb-1 block text-slate-600">Invoice Number</span>
          <input className="input" value={number} onChange={(e) => setNumber(e.target.value)} />
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-slate-600">Member</span>
          <select className="input" value={memberId} onChange={(e) => setMemberId(e.target.value)}>
            <option value="">— none —</option>
            {members.map((m) => (
              <option key={m.id} value={m.id}>{m.name}</option>
            ))}
          </select>
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-slate-600">Period</span>
          <input className="input" value={period} onChange={(e) => setPeriod(e.target.value)} placeholder="2026-07" />
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-slate-600">Due Date</span>
          <input className="input" type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} />
        </label>
        <label className="col-span-2 text-sm">
          <span className="mb-1 block text-slate-600">Line Description</span>
          <input className="input" value={desc} onChange={(e) => setDesc(e.target.value)} />
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-slate-600">Amount (₹)</span>
          <input className="input" value={amount} onChange={(e) => setAmount(e.target.value)} />
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-slate-600">GST/Tax (₹)</span>
          <input className="input" value={tax} onChange={(e) => setTax(e.target.value)} />
        </label>
      </div>
    </Modal>
  );
}

function RecordPaymentModal({
  invoice,
  onClose,
  onSubmit,
  submitting,
}: {
  invoice: Invoice;
  onClose: () => void;
  onSubmit: (amountMinor: number) => void;
  submitting: boolean;
}) {
  const [amount, setAmount] = useState((num(invoice.total_minor) / 100).toString());
  return (
    <Modal
      open
      onClose={onClose}
      title={`Record Payment — ${invoice.number}`}
      footer={
        <>
          <button className="btn-outline" onClick={onClose}>Cancel</button>
          <button
            className="btn-primary"
            disabled={submitting}
            onClick={() => onSubmit(Math.round(Number(amount) * 100))}
          >
            Record Payment
          </button>
        </>
      }
    >
      <p className="mb-3 text-sm text-slate-500">
        Manual/offline payment entry (audited). Razorpay online payments are verified via webhook —
        this does not simulate gateway success.
      </p>
      <label className="text-sm">
        <span className="mb-1 block text-slate-600">Amount (₹)</span>
        <input className="input" value={amount} onChange={(e) => setAmount(e.target.value)} />
      </label>
    </Modal>
  );
}
