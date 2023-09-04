const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function renderTerminalLogs(page, terminalLogs, columns = 240, bufferSize = 100000) {
    return page.evaluate(async (terminalLogs, columns, bufferSize) => {
        const outputs = [];

        const term = new Terminal({
            cols: columns,
            scrollback: bufferSize
        });
        const serializeAddon = new SerializeAddon.SerializeAddon();
        term.loadAddon(serializeAddon);

        for (const terminalLog of terminalLogs) {
            console.log('Rendering terminal log ', terminalLog.substr(0, 240) + '...');

            term.reset();

            const divElement = document.createElement('div');
            term.open(divElement);

            const lines = terminalLog.split(/\r?\n/);
            for (const line of lines) {
                await new Promise((resolve) => {
                    term.write(line + '\r\n', resolve);
                });
            }

            const htmlContent = serializeAddon.serializeAsHTML();
            const tempElement = document.createElement("div");
            tempElement.innerHTML = htmlContent;

            const preElement = tempElement.querySelector("pre");
            if (preElement) {
                const divs = preElement.getElementsByTagName("div");
                for (let i = divs.length - 1; i >= 0; i--) {
                    const div = divs[i];
                    div.appendChild(document.createTextNode("\n"));
                }
            }

            const plainText = tempElement.innerText;
            outputs.push({ htmlContent, plainText });
        }

        return outputs;

    }, terminalLogs, columns, bufferSize);
}


(async () => {
    const browser = await puppeteer.launch({ dumpio: true });
    const page = await browser.newPage();
    // Inject xterm.js and its addon into the page
    await page.addScriptTag({ path: 'node_modules/xterm/lib/xterm.js' });
    await page.addScriptTag({ path: 'node_modules/xterm-addon-serialize/lib/xterm-addon-serialize.js' });

    const terminalLogPaths = process.argv.slice(2);
    const terminalLogs = terminalLogPaths.map(logPath => fs.readFileSync(logPath, 'utf-8'));

    const outputs = await renderTerminalLogs(page, terminalLogs);
    terminalLogPaths.forEach((terminalLogPath, index) => {
        const baseName = path.basename(terminalLogPath, path.extname(terminalLogPath));
        const dirName = path.dirname(terminalLogPath);
        const htmlFilePath = path.join(dirName, `${baseName}.html`);
        const txtFilePath = path.join(dirName, `${baseName}.txt`);
        console.log(
            `Writing ${htmlFilePath} and ${txtFilePath}...`,
        )
        fs.writeFileSync(txtFilePath, outputs[index].plainText);
        fs.writeFileSync(htmlFilePath, outputs[index].htmlContent);
    });

    await browser.close();
})();
