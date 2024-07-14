// ==UserScript==
// @name         Copy Code Button and Auto-Click "Continue Generating" for ChatGPT
// @namespace    https://github.com/RioPlay/RPAUT
// @version      1.0
// @description  Adds a "Copy code" button overlay and auto-clicks "Continue generating" button when it appears on ChatGPT page layout without additional layout adjustments.
// @author       RioPlay
// @match        https://chatgpt.com/*
// @grant        none
// ==/UserScript==

/*!
 * MIT License
 * 
 * Copyright (c) 2024 RioPlay
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

(function() {
    'use strict';

    // Function to add the "Copy code" overlay button
    function addCopyButton() {
        const codeWrappers = document.querySelectorAll('div[class*="dark bg-gray-950 rounded-md border-[0.5px] border-token-border-medium"]');

        codeWrappers.forEach(wrapper => {
            // Check if a copy button already exists to avoid duplication
            if (wrapper.querySelector('.copy-code-button')) return;

            // Create the "Copy code" button
            const copyButton = document.createElement('button');
            copyButton.textContent = 'Copy code';
            copyButton.classList.add('copy-code-button');
            copyButton.style.position = 'absolute';
            copyButton.style.bottom = '10px';
            copyButton.style.right = '10px';
            copyButton.style.padding = '5px 10px';
            copyButton.style.fontSize = '12px';
            copyButton.style.backgroundColor = '#444';
            copyButton.style.color = '#fff';
            copyButton.style.border = 'none';
            copyButton.style.borderRadius = '5px';
            copyButton.style.cursor = 'pointer';
            copyButton.style.opacity = '0.7';
            copyButton.style.zIndex = '10';
            copyButton.onmouseover = () => copyButton.style.opacity = '1';
            copyButton.onmouseout = () => copyButton.style.opacity = '0.7';

            // Append the button to the wrapper
            wrapper.style.position = 'relative';
            wrapper.appendChild(copyButton);

            // Add copy functionality
            copyButton.onclick = () => {
                const codeBlock = wrapper.querySelector('pre code');
                if (codeBlock) {
                    navigator.clipboard.writeText(codeBlock.innerText).then(() => {
                        copyButton.textContent = 'Copied!';
                        setTimeout(() => copyButton.textContent = 'Copy code', 2000);
                    });
                }
            };
        });
    }

    // Function to click the "Continue generating" button
    function clickContinueGenerating() {
        const continueButton = [...document.querySelectorAll('button')].find(btn => btn.innerText === 'Continue generating');
        if (continueButton) {
            continueButton.click();
        }
    }

    // Run the functions when the page loads
    window.addEventListener('load', () => {
        addCopyButton();
        clickContinueGenerating();
    });

    // Run the functions again if the DOM changes (for dynamically loaded content)
    const observer = new MutationObserver((mutations) => {
        for (const mutation of mutations) {
            if (mutation.addedNodes.length) {
                addCopyButton();
                clickContinueGenerating();
                break;
            }
        }
    });
    observer.observe(document.body, { childList: true, subtree: true });
})();
