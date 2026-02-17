import React, { useState, useRef, useEffect } from "react"
import { Icon } from "@iconify/react"

const EnvironmentSelector = ({ environments, selected, onSelect, color }) => {
	const [isOpen, setIsOpen] = useState(false)
	const dropdownRef = useRef(null)

	useEffect(() => {
		const handleClickOutside = (e) => {
			if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
				setIsOpen(false)
			}
		}

		if (isOpen) {
			document.addEventListener("mousedown", handleClickOutside)
		}

		return () => {
			document.removeEventListener("mousedown", handleClickOutside)
		}
	}, [isOpen])

	const handleSelect = (env) => {
		onSelect(env)
		setIsOpen(false)
	}

	const toggleDropdown = (e) => {
		e.stopPropagation()
		e.preventDefault()
		setIsOpen(!isOpen)
	}

	return (
		<div ref={dropdownRef} className="relative inline-block">
			<button
				onClick={toggleDropdown}
				className={`
					pl-2 pr-6 py-0.5 text-xs font-normal cursor-pointer
					bg-black bg-opacity-30 text-${color} rounded-lg
					transition-all duration-200
					hover:bg-opacity-40
					focus:outline-none
					relative
				`}>
				{selected}
				<span
					className={`absolute right-1.5 top-1/2 -translate-y-1/2 pointer-events-none text-${color} opacity-70`}>
					<Icon icon="mdi:chevron-down" width="12" height="12" />
				</span>
			</button>

			{isOpen && (
				<div
					className={`
						absolute top-full left-0 mt-1 z-50
						bg-black bg-opacity-90 rounded-md
						min-w-full overflow-hidden
					`}>
					{environments.map((env, index) => (
						<button
							key={env}
							onClick={() => handleSelect(env)}
							className={`
								block w-full text-left px-3 py-1.5 text-xs
								text-${color} hover:bg-${color} hover:bg-opacity-20
								transition-all duration-150
								${env === selected ? "bg-opacity-20" : ""}
								${index === 0 ? "rounded-t-md" : ""}
								${index === environments.length - 1 ? "rounded-b-md" : ""}
							`}>
							{env}
						</button>
					))}
				</div>
			)}
		</div>
	)
}

export default EnvironmentSelector
