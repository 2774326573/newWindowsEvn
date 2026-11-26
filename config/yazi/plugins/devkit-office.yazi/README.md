# devkit-office.yazi

Repository-owned Yazi 26.9.1 preview adapter. PDF pages render through Poppler;
DOC/DOCX, XLS/XLSX, PPT/PPTX, ODT/ODS/ODP and RTF first convert with LibreOffice.
Each conversion uses a unique temporary directory and LibreOffice user profile.
The source is never modified. Macros are disabled in that profile. Conversions
time out (60 seconds for Office; 30 seconds for rasterization), and have a
200 MiB input size limit. J/K scroll between pages; O opens the original file.
Encrypted and unsupported documents require an external application.

Run the repository installer to generate absolute Python/helper/tool paths.
Do not copy the unexpanded main.lua template directly into a live config.
No remote conversion services, login-time processes or file watchers are used.

License: MIT; see LICENSE in this directory.
