package org.ezyaml.lang.tosca.tests;

import static org.junit.jupiter.api.Assertions.*;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URL;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/*
 * Courtesy https://www.baeldung.com/
 */
public class CsarDownloader {
	private static final String prefix = "csar";
	private static final String suffix = ".csar";

	public static File download(String url) {
		File tempFile = null;
		try (BufferedInputStream in = new BufferedInputStream(new URL(url).openStream());
				FileOutputStream fileOutputStream = new FileOutputStream(
						tempFile = File.createTempFile(prefix, suffix))) {
			byte dataBuffer[] = new byte[1024];
			int bytesRead;
			while ((bytesRead = in.read(dataBuffer, 0, 1024)) != -1) {
				fileOutputStream.write(dataBuffer, 0, bytesRead);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		return tempFile;
	}

	public static File newFile(File destinationDir, ZipEntry zipEntry) throws IOException {
		File destFile = new File(destinationDir, zipEntry.getName());

		String destDirPath = destinationDir.getCanonicalPath();
		String destFilePath = destFile.getCanonicalPath();

		if (!destFilePath.startsWith(destDirPath + File.separator)) {
			throw new IOException("Entry is outside of the target dir: " + zipEntry.getName());
		}

		return destFile;
	}

	public static void unzip(File fileZip, String destDirPath) throws IOException {
		ZipInputStream zis = new ZipInputStream(new FileInputStream(fileZip));
		File destDir = new File(destDirPath);
		if (destDir.exists())
			assertTrue(deleteDirectory(destDir));
		System.out.println("Destination directory created: " + destDir.getCanonicalPath());
		assertTrue(destDir.mkdir());
		byte[] buffer = new byte[1024];
		ZipEntry zipEntry = zis.getNextEntry();
		while (zipEntry != null) {
			File newFile = newFile(destDir, zipEntry);
			File dir = newFile.getParentFile();
			if (!dir.exists())
				dir.mkdirs();
			FileOutputStream fos = new FileOutputStream(newFile);
			int len;
			while ((len = zis.read(buffer)) > 0) {
				fos.write(buffer, 0, len);
			}
			fos.close();
			zipEntry = zis.getNextEntry();
		}
		zis.closeEntry();
		zis.close();
	}

	static boolean deleteDirectory(File directoryToBeDeleted) {
		File[] allContents = directoryToBeDeleted.listFiles();
		if (allContents != null) {
			for (File file : allContents) {
				deleteDirectory(file);
			}
		}
		return directoryToBeDeleted.delete();
	}

	// "https://wiki.onap.org/download/attachments/15992528/resource-Vcpeinfra09-csar.csar"
	public static void main(String[] args) throws IOException {
		File f = download(args.length > 1 && args[0] != null ? args[0]
				: "https://wiki.onap.org/download/attachments/15992528/resource-Vcpeinfra09-csar.csar");
		unzip(f, args.length == 3 && args[1] != null && args[2] != null ? args[1] + "/" + args[2] : "TEMP");
	}
}
