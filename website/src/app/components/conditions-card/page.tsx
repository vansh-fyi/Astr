import { DocPage } from "@/components/docs/documentation";
import { docMeta } from "@/lib/doc-meta";
import * as doc from "@content/components/conditions-card.mdx";

const meta = docMeta(doc);
const Content = doc.default;

export const metadata = { title: meta.title };

export default function Page() {
  return (
    <DocPage meta={meta}>
      <Content />
    </DocPage>
  );
}
