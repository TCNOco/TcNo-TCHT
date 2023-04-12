require('dotenv').config();

const express = require('express');
const userAgent = require('express-useragent');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const app = express();
const port = process.env.PORT || 4200;
const hljs = require('highlight.js');

let fileIndex = new Map();

let folder = './files/';
let dev = false
if (fs.existsSync('isDev.txt')) {
    folder = 'C:/Users/techn/Documents/GitHub/TcNo-TBAG-Files';
    dev = true;
}

// Build MongoDB connection string
const dbUsername = process.env.DB_USERNAME;
const dbPassword = process.env.DB_PASSWORD;
const dbHost = dev ? 'localhost' : (process.env.DB_HOST || 'localhost');
const dbPort = process.env.DB_PORT || 27017;
const dbName = process.env.DB_NAME || 'tbag';
const connectionString = `mongodb://${dbUsername}:${dbPassword}@${dbHost}:${dbPort}/${dbName}?directConnection=true&appName=mongosh+1.5.4`;
console.log(connectionString)

// Connect to MongoDB
mongoose.connect(connectionString, {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

// Define schema and model
const fileVisitSchema = new mongoose.Schema({
    filename: String,
    visits: Number,
    htmlFile: Number,
    rawFile: Number
});

const FileVisit = mongoose.model('files', fileVisitSchema);

// Function to index the ./files/ folder
// Maps "test" : "test.txt"
// and "nestedFunction" : "folder/nestedFunction.ps1"
const languageMap = {
  '.ps1': 'PowerShell',
  '.psm1': 'PowerShell',
  '.bat': 'Batch',
  '.sh': 'Bash',
};
const allowedExtensions = Object.keys(languageMap);
function indexFiles() {

    const indexMap = new Map();
    const indexFilesRecursive = (currentFolder) => {
        const folderContents = fs.readdirSync(currentFolder);
        folderContents.forEach(item => {
            const itemPath = path.join(currentFolder, item);
            const itemStat = fs.statSync(itemPath);

            if (itemStat.isDirectory()) {
                indexFilesRecursive(itemPath);
            } else {
                // Only include specific file extensions
                const extname = path.extname(item).toLowerCase();
                if (allowedExtensions.includes(extname)) {
                    const baseName = path.basename(item, path.extname(item)).toLowerCase();
                    const relativePath = path.relative(folder, itemPath).replace(/\\/g, '/');
                    indexMap.set(baseName, relativePath);
                }
            }
        });
    };

    indexFilesRecursive(folder);
    fileIndex = indexMap;
    console.log(indexMap);
}

// Index the files initially and then every minute
indexFiles();
setInterval(indexFiles, 60 * 1000);

// Read HTML file for beautiful file serving
let htmlFilePage = fs.readFileSync('filePage.html', 'utf8');

app.use(async (req, res, next) => {
    console.log(req.hostname)
    const subdomain = req.hostname.split('.')[0];

    if (fileIndex.has(subdomain)) {
        const originalFilename = fileIndex.get(subdomain);
        console.log(originalFilename)

        if (req.useragent?.source.includes('PowerShell')) {
            // Serve bare PowerShell script
            // Redirect the user to the specified URL
            res.redirect(302, `http://localhost:${port}/raw/${originalFilename}`);
          } else {
            res.redirect(302, `http://localhost:${port}/${originalFilename}`);
          }

    } else {
        const urlPath = req.path;
        const originalFilename = urlPath.replace('/raw/', '').replace(/^\/+/g, '');
        const filePath = path.resolve(folder, originalFilename);
        if (urlPath.startsWith('/raw')) {
            console.log(filePath)
            // Serve raw file
            // Increment the number of visits
            if (!dev){
                const fileVisit = await FileVisit.findOneAndUpdate(
                    { filename: subdomain },
                    { $inc: { visits: 1, rawFile: 1 } },
                    { new: true, upsert: true }
                );
            }
            res.setHeader('Content-Disposition', `attachment; filename=${path.basename(originalFilename)}`);
        
            res.sendFile(filePath, err => {
              if (err) {
                res.status(500).send('Error serving the requested file');
              }
            });

        } else if (fs.existsSync(filePath)) {
            const fileName = filePath
            // Serve nice page with highlighting, etc.
            // Increment the number of visits
            if (!dev){
                const fileVisit = await FileVisit.findOneAndUpdate(
                    { filename: subdomain },
                    { $inc: { visits: 1, htmlFile: 1 } },
                    { new: true, upsert: true }
                );
            }
    
            // Read the file contents
            const fileContents = fs.readFileSync(filePath, 'utf8');
    
            // Highlight the code based on the file extension
            const extension = path.extname(originalFilename);
            const language = languageMap[extension];
            const highlightedCode = hljs.highlight(fileContents, {
                language: language,
                ignoreIllegals: false
                }).value;
            
            // Add filename and contents to page
            let modifiedHtmlContents = htmlFilePage.slice().replaceAll('%filename%', originalFilename).replaceAll('%code%', highlightedCode);
            
            // Send the modified HTML file to the client
            res.setHeader('Content-Type', 'text/html');
            res.send(modifiedHtmlContents);
        } else {
            res.status(404).send('File not found');
        }
    }
});

app.listen(port, () => {
console.log(`Server running at http://localhost:${port}`);
});
