"use client";
import { ReactNode } from "react";
import { Download } from "lucide-react";
import { useApi } from "@/lib/hooks";
import { PageHeader } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { exportCsv, exportPdf, type Column } from "@/lib/export";

export type Col<T> = {
  header: string;
  cell: (row: T) => ReactNode;
  csv?: (row: T) => string | number | null | undefined;
  align?: "left" | "right";
};

export function ResourceList<T extends Record<string, any>>({
  title,
  subtitle,
  path,
  queryKey,
  selectRows,
  columns,
  rowKey,
  exportName,
  headerActions,
  emptyHint,
}: {
  title: string;
  subtitle?: string;
  path: string;
  queryKey: (string | number)[];
  selectRows: (data: any) => T[];
  columns: Col<T>[];
  rowKey: (row: T) => string;
  exportName?: string;
  headerActions?: ReactNode;
  emptyHint?: string;
}) {
  const q = useApi<any>(queryKey, path);
  const rows: T[] = q.data ? selectRows(q.data) || [] : [];

  const csvCols: Column<T>[] = columns
    .filter((c) => c.csv)
    .map((c) => ({ header: c.header, accessor: c.csv! }));

  return (
    <div>
      <PageHeader
        title={title}
        subtitle={subtitle}
        actions={
          <>
            {exportName && csvCols.length > 0 && (
              <>
                <button
                  className="btn-outline"
                  disabled={!rows.length}
                  onClick={() => exportCsv(exportName, csvCols, rows)}
                >
                  <Download className="h-4 w-4" /> CSV
                </button>
                <button
                  className="btn-outline"
                  disabled={!rows.length}
                  onClick={() => exportPdf(exportName, title, csvCols, rows)}
                >
                  <Download className="h-4 w-4" /> PDF
                </button>
              </>
            )}
            {headerActions}
          </>
        }
      />
      {q.isLoading ? (
        <LoadingState />
      ) : q.isError ? (
        <ErrorState onRetry={() => q.refetch()} />
      ) : rows.length === 0 ? (
        <EmptyState hint={emptyHint} />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                {columns.map((c, i) => (
                  <th key={i} className={c.align === "right" ? "text-right" : ""}>
                    {c.header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={rowKey(row)}>
                  {columns.map((c, i) => (
                    <td key={i} className={c.align === "right" ? "text-right" : ""}>
                      {c.cell(row)}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
