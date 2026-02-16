import React, { use, useEffect, useState } from "react"
import Link from "@/components/Link"
import Search from "@/components/Search"
import EnvironmentSelector from "@/components/EnvironmentSelector"
import { useSettings } from "@/context/settings"

const Section = ({ section, filter, selection, isExpanded }) => {
	const alignment = section.align || "left"
	const [selectedEnvironment, setSelectedEnvironment] = useState(
		section.defaultEnvironment || null
	)

	const hasEnvironmentSelector = section.environmentSelector === true
	const environments = hasEnvironmentSelector
		? [...new Set(section.links.map((link) => link.environment).filter(Boolean))]
		: []

	let filteredLinks = hasEnvironmentSelector && selectedEnvironment
		? section.links.filter((link) => link.environment === selectedEnvironment)
		: section.links

	const maxVisible = section.maxVisibleLinks
	const totalLinks = filteredLinks.length
	const hasHiddenLinks = maxVisible && !isExpanded && totalLinks > maxVisible

	if (hasHiddenLinks) {
		filteredLinks = filteredLinks.slice(0, maxVisible)
	}

	return (
		<div className={`mb-4 align-${alignment}`}>
			<div className="flex items-center gap-2 mb-3">
				<h2 className={`text-title font-bold mt-0 mb-0 cursor-default text-${section.color}`}>
					{section.title}
				</h2>

				{hasEnvironmentSelector && environments.length > 0 && (
					<EnvironmentSelector
						environments={environments}
						selected={selectedEnvironment}
						onSelect={setSelectedEnvironment}
						color={section.color}
					/>
				)}
			</div>

			<ul>
				{filteredLinks.map((link, index) => {
					{
						return (
							<Link
								className="font-normal"
								key={index}
								linkData={link}
								filter={filter}
								selection={selection}
							/>
						)
					}
				})}
				{hasHiddenLinks && (
					<li className="-my-2 -ml-3">
						<span className={`ml-2 inline-block px-1 text-${section.color} opacity-40 text-sm`}>
							...
						</span>
					</li>
				)}
			</ul>
		</div>
	)
}

const List = () => {
	const { settings } = useSettings()
	const [command, setCommand] = useState("")
	const [selection, setSelection] = useState("")
	const [isExpanded, setIsExpanded] = useState(false)

	const handleCommandChange = (str) => {
		setCommand(str)
	}

	const handleSelectionChange = (sel) => {
		setSelection(sel)
	}

	const hasCollapsibleSections = settings.sections.list.some(
		(section) => section.maxVisibleLinks && section.links.length > section.maxVisibleLinks
	)

	return (
		<div id="list">
			{hasCollapsibleSections && (
				<div className="flex justify-end px-3 py-2">
					<button
						onClick={() => setIsExpanded(!isExpanded)}
						className="px-2 py-0.5 text-xs font-normal cursor-pointer text-gray opacity-50 hover:opacity-100 transition-opacity duration-200"
					>
						{isExpanded ? "Collapse all" : "Expand all"}
					</button>
				</div>
			)}
			<div className="grid grid-cols-3 gap-4 px-3 py-2 mb-5">
				{settings.sections.list.map((section, index) => {
					return (
						<Section
							key={index}
							section={section}
							filter={command}
							selection={selection}
							isExpanded={isExpanded}
						/>
					)
				})}
			</div>
			<Search commandChange={handleCommandChange} selectionChange={handleSelectionChange} />
		</div>
	)
}

export default List
