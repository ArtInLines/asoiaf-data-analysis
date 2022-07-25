const puppeteer = require('puppeteer');
const fs = require('fs');

const pageLoadingOpts = { waitUntil: 'load', timeout: 0 };

async function getCharLinks(page) {
	await page.goto('https://awoiaf.westeros.org/index.php/List_of_characters', pageLoadingOpts);

	// let acceptBtnSelector = "button[title='Accept']";
	// await Promise.all([page.waitForSelector("button[title='Accept']"), page.click("button[title='Accept']")]);

	let charLinks = await page.$$eval('ul > li', (chars) => {
		return chars.map((el) => el.querySelector('a')?.href);
	});

	firstCharIdx = charLinks.indexOf('https://awoiaf.westeros.org/index.php/A_certain_man');
	lastCharIdx = charLinks.lastIndexOf('https://awoiaf.westeros.org/index.php/Zollo');
	charLinks = charLinks.filter((link, idx) => idx >= firstCharIdx && idx <= lastCharIdx && typeof link === 'string' && link.includes('/index.php/') && !link.includes('redlink=1'));

	fs.writeFileSync('charLinks.json', JSON.stringify(charLinks, null, 4));
}

async function getCharInfo(page) {
	const charLinks = JSON.parse(fs.readFileSync('charLinks.json'));
	const charInfo = {};

	for (let i = 0; i < charLinks.length; i++) {
		let link = charLinks[i];
		await page.goto(link, pageLoadingOpts);
		await page.waitForSelector('table.infobox');
		const table = await page.$('table.infobox');
		const data = await table.$$eval('tr', (rows) => {
			return rows.filter((row) => row.querySelector('th') !== null).map((row) => [row.querySelector('th').innerText, row.querySelector('td')?.innerText]);
		});
		console.log({ link, data });
		charInfo[link] = data;
	}

	fs.writeFileSync('charInfo.json', JSON.stringify(charInfo, null, 4));
}

(async () => {
	const browser = await puppeteer.launch({ headless: false, args: ['--proxy-server=http://70.90.138.109'] });
	const pages = await browser.pages();
	const page = await (pages.length > 0 ? pages[0] : browser.newPage());
	page.setDefaultTimeout(0);

	// await getCharLinks(page);
	await getCharInfo(page);

	await browser.close();
})();
