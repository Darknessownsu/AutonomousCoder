import { pushToGitHub, getUncachableGitHubClient } from '../server/lib/github';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

const REPO_NAME = 'AutonomousCoder';
const DESCRIPTION = 'Native iOS/macOS developer tool for autonomous AI code generation and monitoring. Built with React Native/Expo.';

const IGNORE_PATTERNS = [
  'node_modules',
  '.git',
  '.cache',
  '.expo',
  'dist',
  '.replit',
  'replit.nix',
  '.config',
  'generated-icon.png',
  '*.log',
  '.upm',
];

function shouldIgnore(filePath: string): boolean {
  const relativePath = filePath.replace(/^\.\//, '');
  for (const pattern of IGNORE_PATTERNS) {
    if (pattern.includes('*')) {
      const regex = new RegExp(pattern.replace('*', '.*'));
      if (regex.test(relativePath)) return true;
    } else if (relativePath.startsWith(pattern) || relativePath.includes('/' + pattern)) {
      return true;
    }
  }
  return false;
}

function getAllFiles(dir: string, fileList: string[] = []): string[] {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    if (shouldIgnore(filePath)) continue;
    
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      getAllFiles(filePath, fileList);
    } else {
      fileList.push(filePath);
    }
  }
  return fileList;
}

async function main() {
  try {
    console.log('Creating/finding repository...');
    const repoInfo = await pushToGitHub(REPO_NAME, DESCRIPTION);
    console.log(`Repository URL: ${repoInfo.url}`);
    
    const octokit = await getUncachableGitHubClient();
    
    console.log('Getting all project files...');
    const files = getAllFiles('.');
    console.log(`Found ${files.length} files to upload`);
    
    let existingSha: string | undefined;
    try {
      const { data: refData } = await octokit.git.getRef({
        owner: repoInfo.owner,
        repo: repoInfo.repo,
        ref: 'heads/main',
      });
      existingSha = refData.object.sha;
    } catch (e) {
      console.log('No existing main branch, creating fresh');
    }
    
    console.log('Creating blobs for files...');
    const blobs: { path: string; sha: string; mode: string; type: string }[] = [];
    
    for (const filePath of files) {
      const content = fs.readFileSync(filePath);
      const base64Content = content.toString('base64');
      
      const { data: blob } = await octokit.git.createBlob({
        owner: repoInfo.owner,
        repo: repoInfo.repo,
        content: base64Content,
        encoding: 'base64',
      });
      
      blobs.push({
        path: filePath.replace(/^\.\//, ''),
        sha: blob.sha,
        mode: '100644',
        type: 'blob',
      });
      
      process.stdout.write('.');
    }
    console.log('\nAll blobs created');
    
    console.log('Creating tree...');
    const { data: tree } = await octokit.git.createTree({
      owner: repoInfo.owner,
      repo: repoInfo.repo,
      tree: blobs as any,
      base_tree: existingSha,
    });
    
    console.log('Creating commit...');
    const { data: commit } = await octokit.git.createCommit({
      owner: repoInfo.owner,
      repo: repoInfo.repo,
      message: 'Initial commit: AutonomousCoder - AI code generation monitoring app',
      tree: tree.sha,
      parents: existingSha ? [existingSha] : [],
    });
    
    console.log('Updating main branch...');
    try {
      await octokit.git.updateRef({
        owner: repoInfo.owner,
        repo: repoInfo.repo,
        ref: 'heads/main',
        sha: commit.sha,
      });
    } catch (e) {
      await octokit.git.createRef({
        owner: repoInfo.owner,
        repo: repoInfo.repo,
        ref: 'refs/heads/main',
        sha: commit.sha,
      });
    }
    
    console.log('\n✓ Successfully pushed to GitHub!');
    console.log(`Repository: ${repoInfo.url}`);
    
  } catch (error) {
    console.error('Error pushing to GitHub:', error);
    process.exit(1);
  }
}

main();
