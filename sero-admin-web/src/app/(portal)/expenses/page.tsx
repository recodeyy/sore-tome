"use client";
import { useState } from "react";
import { Plus } from "lucide-react";
import { useApi, useApiMutation, num } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { ResourceList } from "@/components/data/ResourceList";
import { Modal, StatusChip } from "@/components/ui/primitives";
import { formatMoneyMinor, formatDate } from "@/lib/format";

type Expense = {
  id: string;
  vendor: string | null;
  category: string | null;
  description: string;
  amount_minor: string | number;
  status: string;
  created_at: string;
};

export default function ExpensesPage() {
  const { push } = useToast();
  const [open, setOpen] = useState(false);
  const create = useApiMutation("post", [["expenses"]]);
  const [vendor, setVendor] = useState("");
  const [category, setCategory] = useState("utilities");
  const [description, setDescription] = useState("");
  const [amount, setAmount] = useState("");

  return (
    <>
      <ResourceList<Expense>
        title="Expenses"
        subtitle="Society expenditure with approval workflow — live"
        path="/finance/expenses"
        queryKey={["expenses"]}
        selectRows={(d) => d.expenses}
        rowKey={(e) => e.id}
        exportName="expenses"
        emptyHint="No expenses recorded yet."
        headerActions={
          <button className="btn-primary" onClick={() => setOpen(true)}>
            <Plus className="h-4 w-4" /> Add Expense
          </button>
        }
        columns={[
          { header: "Description", cell: (e) => <span className="font-medium">{e.description}</span>, csv: (e) => e.description },
          { header: "Vendor", cell: (e) => e.vendor || "—", csv: (e) => e.vendor || "" },
          { header: "Category", cell: (e) => e.category || "—", csv: (e) => e.category || "" },
          { header: "Amount", align: "right", cell: (e) => formatMoneyMinor(num(e.amount_minor)), csv: (e) => (num(e.amount_minor) / 100).toFixed(2) },
          {
            header: "Status",
            cell: (e) => <StatusChip tone={e.status === "approved" ? "green" : e.status === "rejected" ? "red" : "amber"}>{e.status}</StatusChip>,
            csv: (e) => e.status,
          },
          { header: "Date", cell: (e) => formatDate(e.created_at), csv: (e) => formatDate(e.created_at) },
        ]}
      />

      {open && (
        <Modal
          open
          onClose={() => setOpen(false)}
          title="Add Expense"
          footer={
            <>
              <button className="btn-outline" onClick={() => setOpen(false)}>Cancel</button>
              <button
                className="btn-primary"
                disabled={create.isPending || !description || !amount}
                onClick={() =>
                  create.mutate(
                    {
                      path: "/finance/expenses",
                      body: {
                        vendor: vendor || undefined,
                        category,
                        description,
                        amountMinor: Math.round(Number(amount) * 100),
                      },
                    },
                    {
                      onSuccess: () => {
                        push("success", "Expense added");
                        setOpen(false);
                        setDescription("");
                        setAmount("");
                      },
                      onError: (e) => push("error", e.message),
                    }
                  )
                }
              >
                Save
              </button>
            </>
          }
        >
          <div className="grid grid-cols-2 gap-3">
            <label className="col-span-2 text-sm">
              <span className="mb-1 block text-slate-600">Description</span>
              <input className="input" value={description} onChange={(e) => setDescription(e.target.value)} />
            </label>
            <label className="text-sm">
              <span className="mb-1 block text-slate-600">Vendor</span>
              <input className="input" value={vendor} onChange={(e) => setVendor(e.target.value)} />
            </label>
            <label className="text-sm">
              <span className="mb-1 block text-slate-600">Category</span>
              <input className="input" value={category} onChange={(e) => setCategory(e.target.value)} />
            </label>
            <label className="text-sm">
              <span className="mb-1 block text-slate-600">Amount (₹)</span>
              <input className="input" value={amount} onChange={(e) => setAmount(e.target.value)} />
            </label>
          </div>
        </Modal>
      )}
    </>
  );
}
