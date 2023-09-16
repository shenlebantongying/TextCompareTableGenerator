import java.io.File;
import java.io.FileNotFoundException;
import java.util.*;

public class tcg {

    static class Chunk extends LinkedList<String> {
    }

    private final LinkedList<String> cmpr_titles;
    //FIXME: this type is unclear -> too long
    private final Map<String, LinkedList<Chunk>> cmpr_serialized;

    private int len;

    public tcg(String filepath) {

        cmpr_serialized = new HashMap<>();

        cmpr_titles = new LinkedList<>();

        String cur_content = null;

        try {
            File file = new File(filepath);
            Scanner docReader = new Scanner(file);
            Chunk Content = new Chunk();

            while (docReader.hasNextLine()) {
                String line = docReader.nextLine();
                line = line.stripTrailing();

                if (line.isEmpty()) {
                    continue;
                }

                // FIXME: too ugly here
                if (line.startsWith("```")) {
                    if (line.length() == 3) {
                        cmpr_serialized.computeIfAbsent(cur_content, k -> new LinkedList<>())
                                .add((Chunk) Content.clone());
                        // FIXME:    ^ do u must have this (Chunk) to enforce type?
                        cur_content = null;
                    } else {
                        Content.clear();
                        cur_content = line.substring(3);
                    }
                } else if (cur_content != null) {
                    Content.add(line);
                } else if (line.startsWith("#")) {
                    cmpr_titles.add(line.substring(1).strip());
                }
            }

            docReader.close();

        } catch (FileNotFoundException e) {
            System.err.println("FileNotFound");
        }

    }

    private void print_heading(String i1, String i2) {
        System.out.printf("-%1s%2s+%3s%4s\n",
                i1, "-".repeat(len - i1.length() - 1),
                i2, "-".repeat(len - i2.length()));
    }

    private String addSpaces(String s) {
        return " " + s + " ".repeat(len - s.length() - 1);
    }

    private void print_contentLine(String c1, String c2) {

        System.out.printf("%-1s|%-2s\n", addSpaces(c1), addSpaces(c2));
    }

    private void print_ending() {
        System.out.println("=".repeat(len * 2 + 2));
    }

    public void plainGen() {
        if (cmpr_serialized.size() != 2) {
            System.err.println("Doesn't not support other compare other than two columns");
        }

        String[] cmpr_items = cmpr_serialized.keySet().toArray(new String[2]);

        String item1 = cmpr_items[0];
        String item2 = cmpr_items[1];

        LinkedList<Chunk> item1_contents = cmpr_serialized.get(item1);
        LinkedList<Chunk> item2_contents = cmpr_serialized.get(item2);

        // and cmpr_titles composed 3 lists of neat complete comparison;

        assert item1_contents.size() == item2_contents.size() && item1_contents.size() == cmpr_titles.size();

        int item_size = item1_contents.size();

        // Compute the maximum length from all content lines
        OptionalInt maxContentLength1 = item1_contents.stream()
                .flatMap(List::stream)
                .mapToInt(String::length)
                .max();

        OptionalInt maxContentLength2 = item2_contents.stream()
                .flatMap(List::stream)
                .mapToInt(String::length)
                .max();

        assert maxContentLength1.isPresent();
        assert maxContentLength2.isPresent();

        len = 1 + Math.max(
                maxContentLength1.getAsInt(),
                maxContentLength2.getAsInt()
        );

        LinkedList<String> ic1;
        LinkedList<String> ic2;
        int maxindex_c1;
        int maxindex_c2;

        for (int i = 0; i < item_size; i++) {

            System.out.println(cmpr_titles.get(i));

            print_heading(item1, item2);

            ic1 = item1_contents.get(i);
            ic2 = item2_contents.get(i);

            maxindex_c1 = ic1.size() - 1;
            maxindex_c2 = ic2.size() - 1;

            for (int j = 0; j < Math.max(maxindex_c1, maxindex_c2); j++) {
                if (j <= maxindex_c1 && j <= maxindex_c2) {
                    print_contentLine(ic1.get(j), ic2.get(j));
                } else if (j > maxindex_c2) {
                    print_contentLine(ic1.get(j), "");
                } else {
                    print_contentLine("", ic2.get(j));
                }
            }

            print_ending();
            System.out.println();
        }
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Need single file as input");
            System.exit(1);
        }
        tcg doc = new tcg(args[0]);
        doc.plainGen();
    }
}
